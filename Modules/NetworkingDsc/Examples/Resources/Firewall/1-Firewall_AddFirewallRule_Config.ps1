<#PSScriptInfo
.VERSION 1.0.0
.GUID a675798c-d2b7-4f1b-b59a-b90f2f2e6178
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/NetworkingDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/NetworkingDsc
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
    Allow notepad to access ports on the Domain and Private Profiles.
#>
Configuration Firewall_AddFirewallRule_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        Firewall AddFirewallRule
        {
            Name                  = 'NotePadFirewallRule'
            DisplayName           = 'Firewall Rule for Notepad.exe'
            Group                 = 'NotePad Firewall Rule Group'
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Domain', 'Private')
            Direction             = 'OutBound'
            RemotePort            = ('8080', '8081')
            LocalPort             = ('9080', '9081')
            Protocol              = 'TCP'
            Description           = 'Firewall Rule for Notepad.exe'
            Program               = 'c:\windows\system32\notepad.exe'
            Service               = 'WinRM'
        }
    }
 }
