<#
  This file exists so we can load the test file without necessarily having xNetworking in
  the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File
#>

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
