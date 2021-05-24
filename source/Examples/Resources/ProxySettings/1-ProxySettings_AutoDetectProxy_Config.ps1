<#PSScriptInfo
.VERSION 2.0.0
.GUID 49497e7c-1788-4d3e-a857-f676f88ec70d
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
    Sets the computer to automatically detect the proxy settings.
#>
Configuration ProxySettings_AutoDetectProxy_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        ProxySettings AutoDetectProxy
        {
            Target                  = 'LocalMachine'
            Ensure                  = 'Present'
            EnableAutoDetection     = $true
            EnableAutoConfiguration = $false
            EnableManualProxy       = $false
        }
    }
}
