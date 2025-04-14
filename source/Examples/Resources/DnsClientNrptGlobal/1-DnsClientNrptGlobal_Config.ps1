<#PSScriptInfo
.VERSION 1.0.0
.GUID 1b31527d-8de4-4a7e-a000-9182a0e87cfb
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
        Configure DNS Client NRPT global configuration and set EnableDAForAllNetworks to 'EnableAlways', QueryPolicy to 'QueryBoth' and SecureNameQueryFallback to 'FallbackSecure'.
#>
Configuration DnsClientNrptGlobal_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DnsClientNrptGlobal DnsClientNrptGlobal
        {
            IsSingleInstance        = 'Yes'
            EnableDAForAllNetworks  = 'EnableAlways'
            QueryPolicy             = 'QueryBoth'
            SecureNameQueryFallback = 'FallbackSecure'
        }
    }
}
