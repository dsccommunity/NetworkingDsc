$DSCModuleName = 'xNetworking'
$moduleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if(-not (Test-Path -Path $moduleRoot))
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
}

Copy-Item -Path $PSScriptRoot\..\..\* -Destination $moduleRoot -Recurse -Force -Exclude '.git'

Describe 'xFirewall_Integration' {
    $firewall = Get-NetFirewallRule | select -first 1
    It 'Should compile without throwing' {
        {
            [System.Environment]::SetEnvironmentVariable('PSModulePath', $env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
            . $PSScriptRoot\Firewall.ps1
            Firewall -OutputPath $env:Temp\Firewall
            Start-DscConfiguration -Path $env:Temp\Firewall -ComputerName localhost -Wait -Verbose
        } | Should not throw

        # Cleanup DSC Configuration
        Remove-Item -Path $env:Temp\Firewall -Recurse -Force
    }

    It 'should be able to call Get-DscConfiguration without throwing' {
        {Get-DscConfiguration} | Should Not throw
    }
}

# Clean up after the test completes.
Remove-Item -Path $moduleRoot -Recurse -Force