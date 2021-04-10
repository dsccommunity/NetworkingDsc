<#PSScriptInfo
.VERSION 1.0.0
.GUID bd77b4d0-f97f-47c9-890f-b75abded7bcb
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
    This configuration disables the network adapter named Ethernet.
#>
Configuration NetAdapterState_Disable_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterState EnableEthernet
        {
            Name     = 'Ethernet'
            State    = 'Disabled'
        }
    }
}
