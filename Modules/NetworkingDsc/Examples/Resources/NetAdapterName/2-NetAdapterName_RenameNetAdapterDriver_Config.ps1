<#PSScriptInfo
.VERSION 1.0.0
.GUID 64fb258c-2f8d-4db6-91f9-631fbe821a18
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
    Rename the first three network adapters with Driver Description matching
    'Hyper-V Virtual Ethernet Adapter' in consequtive order to Cluster, Management
    and SMB and then enable DHCP on them.
#>
Configuration NetAdapterName_RenameNetAdapterDriver_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterName RenameNetAdapterCluster
        {
            NewName           = 'Cluster'
            DriverDescription = 'Hyper-V Virtual Ethernet Adapter'
            InterfaceNumber   = 1
        }

        NetIPInterface EnableDhcpClientCluster
        {
            InterfaceAlias = 'Cluster'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Enabled'
        }

        NetAdapterName RenameNetAdapterManagement
        {
            NewName           = 'Management'
            DriverDescription = 'Hyper-V Virtual Ethernet Adapter'
            InterfaceNumber   = 2
        }

        NetIPInterface EnableDhcpClientManagement
        {
            InterfaceAlias = 'Management'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Enabled'
        }

        NetAdapterName RenameNetAdapterSMB
        {
            NewName           = 'SMB'
            DriverDescription = 'Hyper-V Virtual Ethernet Adapter'
            InterfaceNumber   = 3
        }

        NetIPInterface EnableDhcpClientSMB
        {
            InterfaceAlias = 'SMB'
            AddressFamily  = 'IPv4'
            Dhcp           = 'Enabled'
        }
    }
}
