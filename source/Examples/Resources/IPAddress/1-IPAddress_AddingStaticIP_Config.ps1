<#PSScriptInfo
.VERSION 1.0.0
.GUID 2868f85b-b58c-4be1-b2e6-a9da0d1cb2a1
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
    using default prefix lengths for the matching address classes.
#>
Configuration IPAddress_AddingStaticIP_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface DisableDhcp
        {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Disabled'
        }

        # If no prefix is supplied IPv6 will default to /64.
        IPAddress NewIPv6Address
        {
            IPAddress      = '2001:4898:200:7:6c71:a102:ebd8:f482'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV6'
        }

        <#
            If no prefix is supplied then IPv4 will default to class based:
            - Class A - /8
            - Class B - /16
            - Class C - /24
        #>
        IPAddress NewIPv4Address
        {
            IPAddress      = '192.168.10.5'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV4'
        }
    }
}
