<#PSScriptInfo
.VERSION 1.0.0
.GUID e735c036-7b8f-4d06-8be9-96d78784093b
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
    Disable the weak host send IPv4 setting for the network adapter with alias 'Ethernet'.
#>
Configuration NetIPInterface_DisableWeakHostSend_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface DisableWeakHostSend
        {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            WeakHostSend   = 'Disabled'
        }
    }
}
