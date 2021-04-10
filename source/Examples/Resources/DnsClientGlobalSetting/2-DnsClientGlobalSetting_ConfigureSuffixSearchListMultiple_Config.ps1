<#PSScriptInfo
.VERSION 1.0.0
.GUID 8f82152a-d833-4752-a9f1-7960bda73536
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
    Configure fabrikam.com and fourthcoffee.com for the DNS SuffixSearchList.
#>
Configuration DnsClientGlobalSetting_ConfigureSuffixSearchListMultiple_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DnsClientGlobalSetting ConfigureSuffixSearchListMultiple
        {
            IsSingleInstance = 'Yes'
            SuffixSearchList = ('fabrikam.com', 'fourthcoffee.com')
            UseDevolution    = $true
            DevolutionLevel  = 0
        }
    }
}
