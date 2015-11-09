<#
  This file exists so we can load the test file without necessarily having xNetworking in
  the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File
#>

$rule = @{
    Name         = 'b8df0af9-d0cc-4080-885b-6ed263aaed67'
    DisplayGroup = 'b8df0af9-d0cc-4080-885b-6ed263aaed67'
    Ensure       = 'Present'
    Enabled      = 'False'
    Profile      = 'Domain, Private'
    Action       = 'Allow'
    Description  = 'MSFT_xFirewall Test Firewall Rule'
    Direction    = 'Inbound'
}

Configuration Firewall {
    Import-DscResource -ModuleName xNetworking
    node localhost {
       xFirewall Integration_Test {
            Name            = $rule.Name
            DisplayGroup    = $rule.DisplayGroup
            Ensure          = 'Present'
            Enabled         = $rule.Enabled
            Profile         = ($rule.Profile).toString()
            Action          = $rule.Action
            Description     = $rule.Description
            Direction       = $rule.Direction
        }
    }
}
