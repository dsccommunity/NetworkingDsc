<#PSScriptInfo
.VERSION 1.0.0
.GUID 87e17ee4-64b0-476a-8aa8-1018a5de6353
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
    Add an NRPT rule to enable DNSSEC queries.
#>
Configuration DnsClientNrptRule_DNSSEC_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DnsClientNrptRule DNSSEC
        {
            Name         = 'DNSSEC'
            Namespace    = 'contoso.com'
            DnsSecEnable = $true
        }
    }
}
