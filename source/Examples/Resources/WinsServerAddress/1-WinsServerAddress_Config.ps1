<#PSScriptInfo
.VERSION 1.0.0
.GUID 024703ca-5620-4f5e-903a-bd0120e72348

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
    Configure WINS Server for the Ethernet adapter.
#>
Configuration WinsServerAddress_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        WinsServerAddress WinsServerAddress
        {
            Address        = '192.168.0.1'
            InterfaceAlias = 'Ethernet'
        }
    }
}
