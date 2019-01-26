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
    This configuration disables RSC on the network adapter.
#>
Configuration NetAdapterRsc_DisableRscAll_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterRsc DisableRscIPv4
        {
            Name = 'Ethernet'
            Protocol = 'All'
            State = $false
        }
    }
}
