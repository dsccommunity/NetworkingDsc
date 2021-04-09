<#PSScriptInfo
.VERSION 1.0.0
.GUID ddfc1fed-3418-40ba-b003-f8dc244838e7
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
    This configuration disables LSO for IPv6 on the network adapter.
#>
Configuration NetAdapterLso_DisableLsoIPv6_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterLso DisableLsoIPv6
        {
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $false
        }
    }
}
