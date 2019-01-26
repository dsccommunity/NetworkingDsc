<#PSScriptInfo
.VERSION 1.0.0
.GUID de123ac9-1b72-4d40-a5b2-a06e9de8c81d
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
    Set the IPv4 default gateway of the network interface 'Ethernet'
    to '192.168.1.1'.
#>
Configuration DefaultGatewayAddress_SetDefaultGateway_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DefaultGatewayAddress SetDefaultGateway
        {
            Address        = '192.168.1.1'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }
    }
}
