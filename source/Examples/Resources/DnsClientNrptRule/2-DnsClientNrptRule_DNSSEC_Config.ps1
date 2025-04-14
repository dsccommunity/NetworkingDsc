<#PSScriptInfo
.VERSION 1.0.0
.GUID 2c8c4bf7-04ca-464a-941b-3b95c566693d
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
        Sets a DNS Client NRPT rule named 'DNSSEC' to enable DNSSEC queries for a specific namespace (contoso.com).
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
