<#PSScriptInfo
.VERSION 1.0.0
.GUID b43f8fac-cc5a-45ec-ab7d-344dff0b31e7
.AUTHOR Mike Kletz
.COMPANYNAME
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
