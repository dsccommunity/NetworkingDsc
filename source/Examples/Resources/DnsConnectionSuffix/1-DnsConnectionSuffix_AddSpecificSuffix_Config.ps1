<#PSScriptInfo
.VERSION 1.0.0
.GUID bb3f31aa-09bc-46c4-bf60-35c5702934b3
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
    This configuration will set a DNS connection-specific suffix on a network interface that
    is identified by its alias.
#>
Configuration DnsConnectionSuffix_AddSpecificSuffix_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DnsConnectionSuffix AddSpecificSuffix
        {
            InterfaceAlias           = 'Ethernet'
            ConnectionSpecificSuffix = 'contoso.com'
        }
    }
}
