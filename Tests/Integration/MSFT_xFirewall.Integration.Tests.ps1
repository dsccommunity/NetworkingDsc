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
            [System.Environment]::SetEnvironmentVariable('PSModulePath',$env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
            Firewall -OutputPath $env:Temp

            . $PSScriptRoot\Firewall.ps1

            Start-DscConfiguration -Path $env:Temp -ComputerName localhost -Wait -Verbose
        } | Should not throw
    }

    It 'should be able to call Get-DscConfiguration without throwing' {
        {Get-DscConfiguration} | Should Not throw
    }
}
