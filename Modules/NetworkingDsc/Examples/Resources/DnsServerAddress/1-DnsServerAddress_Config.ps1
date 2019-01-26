<#PSScriptInfo
.VERSION 1.0.0
.GUID
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
    Configure DNS Server for the Ethernet adapter.
#>
Configuration DnsServerAddress_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DnsServerAddress DnsServerAddress
        {
            Address        = '127.0.0.1'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Validate       = $true
        }
    }
}
