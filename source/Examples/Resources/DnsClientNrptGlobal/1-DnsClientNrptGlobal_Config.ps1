<#PSScriptInfo
.VERSION 1.0.0
.GUID ef9d0f9a-5a08-43c0-9645-48e103188971
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
    Configure the NRPT global configuration.
#>
Configuration DnsClientNrptGlobal_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DnsClientNrptGlobal DnsClientNrptGlobal
        {
            IsSingleInstance        = 'Yes'
            EnableDAForAllNetworks  = 'Disable'
            QueryPolicy             = 'Disable'
            SecureNameQueryFallback = 'Disable'
        }
    }
}
