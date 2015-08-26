$DSCResourceName = 'MSFT_xFirewall'

if (Get-Module $DSCResourceName -All)
{
    Get-Module $DSCResourceName -All | Remove-Module
}

Import-Module -Name $PSScriptRoot\..\..\DSCResources\$DSCResourceName -Force -DisableNameChecking

InModuleScope $DSCResourceName {
Describe 'xFirewall_Integration' {
    $firewall = Get-NetFirewallRule | select -first 1

    try {
        It 'Should compile without throwing' {
        {
            [System.Environment]::SetEnvironmentVariable('PSModulePath',$env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
            Configuration Firewall {
                Import-DscResource -ModuleName xNetworking
                node localhost {
                   xFirewall Integration_Test {
                        Name = $firewall.Name
                        DisplayGroup = $firewall.DisplayGroup
                        Ensure = 'Present'
                        Enabled = $firewall.Enabled
                        Profile = ($firewall.Profile).toString()
                        Description = $firewall.Description
                        LocalPort = $firewall.LocalPort
                        Protocol = $firewall.Protocol
                        Direction = $firewall.Direction
                        ApplicationPath = $firewall.ApplicationPath
                    }
                }
            }

            Firewall -OutputPath $env:Temp

            Start-DscConfiguration -Path $env:Temp -ComputerName localhost -Wait -Verbose
        } | Should not throw
    }

        It 'should be able to call Get-DscConfiguration without throwing' {
            {Get-DscConfiguration} | Should Not throw
        }
    }
    finally {

    }
}

}
