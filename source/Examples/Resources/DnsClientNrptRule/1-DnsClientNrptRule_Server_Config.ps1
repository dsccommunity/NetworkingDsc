<#PSScriptInfo
.VERSION 1.0.0
.GUID ffeb7cf3-f0d8-4e26-8f1f-132d889e639b
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
    Add an NRPT rule to configure a server.
#>
Configuration DnsClientNrptRule_Server_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DnsClientNrptRule Server
        {
            Name        = 'Server'
            Namespace   = '.contoso.com'
            NameServers = ('192.168.1.1')
        }
    }
}
