<#PSScriptInfo
.VERSION 1.0.0
.GUID 50924e43-8e8f-46cb-a1cc-c3a16531f2fd
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
    Disabling DHCP and adding a static IP Address for IPv6 and IPv4
    using specified prefixes in CIDR notation.
#>
Configuration IPAddress_AddingStaticIPWithPrefix_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface DisableDhcp
        {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv6'
            Dhcp           = 'Disabled'
        }

        IPAddress NewIPv6Address
        {
            IPAddress      = '2001:4898:200:7:6c71:a102:ebd8:f482/64'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV6'
        }

        IPAddress NewIPv4Address
        {
            IPAddress      = '192.168.10.5/24'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV4'
        }
    }
}
