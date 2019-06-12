<#PSScriptInfo
.VERSION 1.0.0
.GUID 87e17ee4-64b0-476a-8aa8-1018a5de6353
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/NetworkingDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/NetworkingDsc
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
