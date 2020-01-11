<#PSScriptInfo
.VERSION 1.0.0
.GUID 1c89b512-4b55-4222-98c2-6d447cbac129
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
    This configuration disables RSC for IPv6 on the network adapter.
#>
Configuration NetAdapterRsc_DisableRscIPv6_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterRsc DisableRscIPv6
        {
            Name = 'Ethernet'
            Protocol = 'IPv6'
            State = $false
        }
    }
}
