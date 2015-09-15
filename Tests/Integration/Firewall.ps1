<#
  This file exists so we can load the test file without necessarily having xNetworking in
  the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File
#>

$rule = Get-NetFirewallRule | Sort-Object Name | Where-Object {$_.DisplayGroup -ne $null} | Select-Object -first 1

Configuration Firewall {
    Import-DscResource -ModuleName xNetworking
    node localhost {
       xFirewall Integration_Test {
            Name = $rule.Name
            DisplayGroup = $rule.DisplayGroup
            Ensure = 'Present'
            Enabled = $rule.Enabled
            Profile = ($rule.Profile).toString()
            Description = $rule.Description
            LocalPort = $rule.LocalPort
            Protocol = $rule.Protocol
            Direction = $rule.Direction
            ApplicationPath = $rule.ApplicationPath
        }
    }
}
