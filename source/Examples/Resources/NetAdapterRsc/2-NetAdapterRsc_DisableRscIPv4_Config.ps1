<#PSScriptInfo
.VERSION 1.0.0
.GUID 6e5c605a-4c35-4c58-84f0-c34d6d8d116b
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
    This configuration disables RSC for IPv4 on the network adapter.
#>
Configuration NetAdapterRsc_DisableRscIPv4_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterRsc DisableRscIPv4
        {
            Name = 'Ethernet'
            Protocol = 'IPv4'
            State = $false
        }
    }
}
