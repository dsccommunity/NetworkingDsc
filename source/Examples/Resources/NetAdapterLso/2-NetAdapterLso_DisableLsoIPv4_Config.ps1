<#PSScriptInfo
.VERSION 1.0.0
.GUID 167d0cfe-47d6-43b9-b95f-a5893c178ae8
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
    This configuration disables LSO for IPv4 on the network adapter.
#>
Configuration NetAdapterLso_DisableLsoIPv4_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterLso DisableLsoIPv4
        {
            Name     = 'Ethernet'
            Protocol = 'IPv4'
            State    = $false
        }
    }
}
