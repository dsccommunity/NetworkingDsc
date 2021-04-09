<#PSScriptInfo
.VERSION 1.0.0
.GUID 28ca3005-2ec5-4e0a-acb0-084b459e6303
.AUTHOR DSC Community
.COMPANYNAME DSC Community
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
    Sets the Ethernet adapter to Private but does not change
    IPv4 or IPv6 connectivity.
#>
Configuration NetConnectionProfile_SetPrivate_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetConnectionProfile SetPrivate
        {
            InterfaceAlias   = 'Ethernet'
            NetworkCategory  = 'Private'
        }
    }
}
