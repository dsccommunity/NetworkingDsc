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
    Configure primary and secondary DNS Server addresses on the Ethernet adapter.
#>
Configuration DnsServerAddress_PrimaryAndSecondary_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DnsServerAddress DnsServerAddress
        {
            Address        = '10.0.0.2','10.0.0.40'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            Validate       = $true
        }
    }
}
