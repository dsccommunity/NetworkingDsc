<#PSScriptInfo
.VERSION 1.0.0
.GUID 1b144c2a-c111-40bd-b3ac-8d3209de3b5c
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
    DSC configuration that enables the built-in Firewall Rule
    'World Wide Web Services (HTTP Traffic-In)'.
#>
Configuration Firewall_EnableBuiltInFirewallRule_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        Firewall EnableBuiltInFirewallRule
        {
            Name                  = 'IIS-WebServerRole-HTTP-In-TCP'
            Ensure                = 'Present'
            Enabled               = 'True'
        }
    }
}
