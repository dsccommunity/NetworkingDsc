$DSCModuleName = 'xNetworking'
$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}
else
{
    # Copy the existing folder out to the temp directory to hold until the end of the run
    # Delete the folder to remove the old files.
    $tempLocation = Join-Path -Path $env:Temp -ChildPath $DSCModuleName
    Copy-Item -Path $moduleRoot -Destination $tempLocation -Recurse -Force
    Remove-Item -Path $moduleRoot -Recurse -Force
    $null = New-Item -Path $moduleRoot -ItemType Directory
}

Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

if (Get-Module -Name $DSCModuleName -All)
{
    Get-Module -Name $DSCModuleName -All | Remove-Module
}

Import-Module -Name $(Get-Item -Path (Join-Path $moduleRoot -ChildPath "$DSCModuleName.psd1")) -Force

if (($env:PSModulePath).Split(';') -ccontains $pwd.Path)
{
    $script:tempPath = $env:PSModulePath
    $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object {$_ -ne $pwd.path}) -join ';'
}

# Preserve and set the execution policy so that the DSC MOF can be created
$OldExecutionPolicy = Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

try {
    # Load in the DSC Configuration
    . $PSScriptRoot\Firewall.ps1

    Describe 'xFirewall_Integration' {
        It 'Should compile without throwing' {
            {
                [System.Environment]::SetEnvironmentVariable('PSModulePath',
                    $env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
                Firewall -OutputPath $env:Temp\Firewall
                Start-DscConfiguration -Path $env:Temp\Firewall -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            {Get-DscConfiguration} | Should Not throw
        }

        It 'Should have set the firewall and all the parameters should match' {
            $firewallRule = Get-NetFireWallRule -Name $rule.Name

            $firewallRule.Name         | Should Be $rule.Name
            $firewallRule.DisplayName  | Should Be $rule.DisplayName
            $firewallRule.Group        | Should Be $rule.Group
            $firewallRule.Enabled      | Should Be $rule.Enabled
            $firewallRule.Profile      | Should Be $rule.Profile
            $firewallRule.Action       | Should Be $rule.Action
            $firewallRule.Description  | Should Be $rule.Description
            $firewallRule.Direction    | Should Be $rule.Direction
        }

    }
}
finally {
    # Restore the Execution Policy
    Set-ExecutionPolicy -ExecutionPolicy $OldExecutionPolicy -Force

    # Cleanup DSC Configuration
    Remove-NetFirewallRule -Name 'b8df0af9-d0cc-4080-885b-6ed263aaed67'
    Remove-Item -Path $env:Temp\Firewall -Recurse -Force

    # Clean up after the test completes.
    Remove-Item -Path $moduleRoot -Recurse -Force

    # Restore previous versions, if it exists.
    if ($tempLocation)
    {
        $null = New-Item -Path $moduleRoot -ItemType Directory
        Copy-Item -Path $tempLocation -Destination "${env:ProgramFiles}\WindowsPowerShell\Modules" -Recurse -Force
        Remove-Item -Path $tempLocation -Recurse -Force
    }
}
