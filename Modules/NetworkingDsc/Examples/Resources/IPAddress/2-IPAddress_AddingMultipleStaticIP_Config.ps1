<#PSScriptInfo
.VERSION 1.0.0
.GUID 801a7f00-6385-4954-9393-a86acbad5b26
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
    Disabling DHCP and adding multiple static IP Addresses for IPv4 and IPv6.
#>
Configuration IPAddress_AddingMultipleStaticIP_Config
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
            IPAddress      = '2001:4898:200:7:6c71:a102:ebd8:f482/64','2001:4598:210:7:6d71:a102:ebe8:f483/64'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV6'
        }

        IPAddress NewIPv4Address
        {
            IPAddress      = '192.168.10.5/24','192.168.10.6/24'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV4'
        }
    }
}
