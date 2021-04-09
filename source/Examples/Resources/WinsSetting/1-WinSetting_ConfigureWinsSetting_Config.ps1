<#PSScriptInfo
.VERSION 1.0.0
.GUID 07662187-c8da-4665-b190-a1256764c4b8
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
    Disable LMHOSTS lookup and disable using DNS for WINS name resolution.
#>
Configuration WinSetting_ConfigureWinsSetting_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        WinsSetting ConfigureWinsSettings
        {
            IsSingleInstance = 'Yes'
            EnableLMHOSTS    = $false
            EnableDNS        = $false
        }
    }
}
