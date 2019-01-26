<#PSScriptInfo
.VERSION 1.0.0
.GUID 63b226f9-6668-4759-a69f-6cadda2dac76
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
    Enabling DHCP for the IPv4 Address and DNS on the adapter with alias 'Ethernet'.
#>
Configuration NetIPInterface_EnableDHCP_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface EnableDhcp
        {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Enabled'
        }

        DnsServerAddress EnableDhcpDNS
        {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }
    }
}
