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

Import-Module -Name $DSCModuleName -Force

Describe 'xFirewall_Integration' {
    It 'Should compile without throwing' {
        {
            [System.Environment]::SetEnvironmentVariable('PSModulePath',
                $env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
            . $PSScriptRoot\Firewall.ps1
            Firewall -OutputPath $env:Temp\Firewall
            Start-DscConfiguration -Path $env:Temp\Firewall -ComputerName localhost -Wait -Verbose -Force
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

# Restore previous versions, if it exists.
if ($tempLocation)
{
    $null = New-Item -Path $moduleRoot -ItemType Directory
    Copy-Item -Path $tempLocation -Destination "${env:ProgramFiles}\WindowsPowerShell\Modules" -Recurse -Force
    Remove-Item -Path $tempLocation -Recurse -Force
}
