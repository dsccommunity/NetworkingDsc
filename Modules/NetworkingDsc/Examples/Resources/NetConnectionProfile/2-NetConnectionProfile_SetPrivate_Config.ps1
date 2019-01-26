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
    Sets the Ethernet adapter to Private but does not change
    IPv4 or IPv6 connectivity.
#>
Configuration NetConnectionProfile_SetPrivate_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetConnectionProfile Example
        {
            InterfaceAlias   = 'Ethernet'
            NetworkCategory  = 'Private'
        }
    }
}
