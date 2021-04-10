<#PSScriptInfo
.VERSION 1.0.0
.GUID 52dee304-802b-4223-8850-63ace6043c6d
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
    Remove the IPv4 default gateway from the network interface
    'Ethernet'.
#>
Configuration DefaultGatewayAddress_RemoveDefaultGateway_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        DefaultGatewayAddress RemoveDefaultGateway
        {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }
    }
}
