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
        Sets a Dns Client NRPT rule to send Punycode DNS queries using a conditional dns forwarder for a specific namespace.
    .PARAMETER Name
        Specifies the name which uniquely identifies a rule.
    .PARAMETER NameEncoding
        Specifies the encoding format for host names in the DNS query.
    .PARAMETER NameServers
        Specifies the DNS servers to which the DNS query is sent when DirectAccess is disabled.
    .PARAMETER Namespace
        Specifies the DNS namespace.
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
