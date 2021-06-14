<#PSScriptInfo
.VERSION 2.0.0
.GUID f58d84ef-844e-4ce1-8536-5daceb52cede
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
    Sets the computer to use an automatic WPAD configuration script that will
    be downloaded from the URL 'http://wpad.contoso.com/wpad.dat'.
#>
Configuration ProxySettings_AutoConfigurationProxy_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        ProxySettings AutoConfigurationProxy
        {
            Target                  = 'LocalMachine'
            Ensure                  = 'Present'
            EnableAutoDetection     = $false
            EnableAutoConfiguration = $true
            EnableManualProxy       = $false
            AutoConfigURL           = 'http://wpad.contoso.com/wpad.dat'
        }
    }
}
