<#PSScriptInfo
.VERSION 1.0.0
.GUID 355eb49c-b71a-4d92-adf0-9a2dbd0b7918
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
    This configuration changes the JumboPacket Size.
#>
Configuration NetAdapterAdvancedProperty_JumboPacket_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterAdvancedProperty JumboPacket9014
        {
            NetworkAdapterName  = 'Ethernet'
            RegistryKeyword     = "*JumboPacket"
            RegistryValue       = 9014
        }
    }
}
