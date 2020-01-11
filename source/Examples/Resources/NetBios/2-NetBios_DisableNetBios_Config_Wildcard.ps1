<#PSScriptInfo
.VERSION 1.0.0
.GUID b43f8fac-cc5a-45ec-ab7d-344dff0b31e7
.AUTHOR Mike Kletz
.COMPANYNAME
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
    Disable NetBios on all adapters.
#>
Configuration NetBios_DisableNetBios_Config_Wildcard
{
    Import-DscResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetBios DisableNetBios
        {
            InterfaceAlias = '*'
            Setting        = 'Disable'
        }
    }
}
