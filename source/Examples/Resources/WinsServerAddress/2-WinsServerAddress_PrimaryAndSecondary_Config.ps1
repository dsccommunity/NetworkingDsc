<#PSScriptInfo
.VERSION 1.0.0
.GUID a36423e1-e828-4079-a0d7-91d7069ee80f
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
    Configure primary and secondary WINS Server addresses on the Ethernet adapter.
#>
Configuration WinsServerAddress_PrimaryAndSecondary_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        WinsServerAddress PrimaryAndSecondary
        {
            Address        = '192.168.0.1', '192.168.0.2'
            InterfaceAlias = 'Ethernet'
        }
    }
}
