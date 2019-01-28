<#PSScriptInfo
.VERSION 1.0.0
.GUID ef34f3d9-826f-4e01-81fb-3980d07efcfe
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
    Sets the Ethernet adapter to Public and IPv4/6 to Internet Connectivity.
#>
Configuration NetConnectionProfile_SetPublicEnableInternet_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetConnectionProfile SetPublicEnableInternet
        {
            InterfaceAlias   = 'Ethernet'
            NetworkCategory  = 'Public'
            IPv4Connectivity = 'Internet'
            IPv6Connectivity = 'Internet'
        }
    }
}
