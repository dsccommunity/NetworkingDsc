<#PSScriptInfo
.VERSION 1.0.0
.GUID 2a7078e0-8656-4a62-adbe-2eb12a8a4714
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
    Disable the weak host receive IPv4 setting for the network adapter with alias 'Ethernet'.
#>
Configuration NetIPInterface_DisableWeakHostReceive_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface DisableWeakHostReceiving
        {
            InterfaceAlias  = 'Ethernet'
            AddressFamily   = 'IPv4'
            WeakHostReceive = 'Disabled'
        }
    }
}
