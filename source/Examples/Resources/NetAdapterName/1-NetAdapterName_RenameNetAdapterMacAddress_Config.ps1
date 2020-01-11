<#PSScriptInfo
.VERSION 1.0.0
.GUID fe77b7b8-292d-4112-8920-79c724bccb83
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
    Rename three network adapters identified by MAC addresses to
    Cluster, Management and SMB and then enable DHCP on them.
#>
Configuration NetAdapterName_RenameNetAdapterMacAddress_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterName RenameNetAdapterCluster
        {
            NewName    = 'Cluster'
            MacAddress = '9C-D2-1E-61-B5-DA'
        }

        NetIPInterface EnableDhcpClientCluster
        {
            InterfaceAlias = 'Cluster'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Enabled'
        }

        NetAdapterName RenameNetAdapterManagement
        {
            NewName    = 'Management'
            MacAddress = '9C-D2-1E-61-B5-DB'
        }

        NetIPInterface EnableDhcpClientManagement
        {
            InterfaceAlias = 'Management'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Enabled'
        }

        NetAdapterName RenameNetAdapterSMB
        {
            NewName    = 'SMB'
            MacAddress = '9C-D2-1E-61-B5-DC'
        }

        NetIPInterface EnableDhcpClientSMB
        {
            InterfaceAlias = 'SMB'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Enabled'
        }
    }
}
