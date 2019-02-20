<#PSScriptInfo
.VERSION 1.0.0
.GUID 8b3b641c-fcda-405c-ae6b-c4331ad87aa7
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
    Disable NetBios on Adapter.
#>
Configuration NetBios_DisableNetBios_Config
{
    Import-DscResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetBios DisableNetBios
        {
            InterfaceAlias = 'Ethernet'
            Setting        = 'Disable'
        }
    }
}
