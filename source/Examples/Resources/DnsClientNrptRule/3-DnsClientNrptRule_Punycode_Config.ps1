<#PSScriptInfo
.VERSION 1.0.0
.GUID eafe8bba-ac2c-4509-b6c5-3dc9d57facfd
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
    Add an NRPT rule to send Punycode DNS queries.
#>
Configuration DnsClientNrptRule_Punycode_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DnsClientNrptRule Punycode
        {
            Name         = 'Punycode'
            Namespace    = 'contoso.com'
            NameEncoding = 'Punycode'
            NameServers  = ('192.168.1.1')
        }
    }
}
