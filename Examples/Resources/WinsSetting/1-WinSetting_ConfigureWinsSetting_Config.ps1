<#PSScriptInfo
.VERSION 1.0.0
.GUID 0955cec0-5a87-4a2c-b33e-84913ebd8374
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
