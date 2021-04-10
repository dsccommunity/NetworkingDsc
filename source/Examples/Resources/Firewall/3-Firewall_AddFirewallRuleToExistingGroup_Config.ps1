<#PSScriptInfo
.VERSION 1.0.0
.GUID 6121a928-6d18-4b48-8261-d2bea7036a8d
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/NetworkingDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/NetworkingDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module NetworkingDsc

<#
    .DESCRIPTION
    Adding a firewall to an existing Firewall group 'My Firewall Rule'.
#>
Configuration Firewall_AddFirewallRuleToExistingGroup_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        Firewall AddFirewallRuleToExistingGroup
        {
            Name                  = 'MyFirewallRule'
            DisplayName           = 'My Firewall Rule'
            Group                 = 'My Firewall Rule Group'
        }

        Firewall Firewall1
        {
            Name                  = 'MyFirewallRule1'
            DisplayName           = 'My Firewall Rule'
            Group                 = 'My Firewall Rule Group'
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Domain', 'Private')
        }
    }
}
