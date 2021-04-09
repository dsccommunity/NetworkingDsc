<#PSScriptInfo
.VERSION 1.0.0
.GUID c67b7df4-bafa-4bca-bb43-349b44df3530
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
    Set a specified interface metrics for the network adapters with alias 'Ethernet' and 'Ethernet 2'.
#>
Configuration NetIPInterface_SetInterfaceMetric
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface EthernetMetric
        {
            InterfaceAlias  = 'Ethernet'
            AddressFamily   = 'IPv4'
            AutomaticMetric = 'Disabled'
            InterfaceMetric = 10
        }

        NetIPInterface Ethernet2Metric
        {
            InterfaceAlias  = 'Ethernet 2'
            AddressFamily   = 'IPv4'
            AutomaticMetric = 'Disabled'
            InterfaceMetric = 20
        }
    }
}
