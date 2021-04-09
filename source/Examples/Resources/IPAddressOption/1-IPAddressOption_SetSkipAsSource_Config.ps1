<#PSScriptInfo
.VERSION 1.0.0
.GUID 6b9aa735-cd10-45b0-813a-13f86f9f2b00
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
    Change the SkipAsSource option for a single IP address.
#>
Configuration IPAddressOption_SetSkipAsSource_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        IPAddressOption SetSkipAsSource
        {
            IPAddress    = '192.168.10.5'
            SkipAsSource = $true
        }
    }
}
