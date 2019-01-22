<#
    .EXAMPLE
    Rename the first three network adapters with Driver Description matching
    'Hyper-V Virtual Ethernet Adapter' in consequtive order to Cluster, Management
    and SMB and then enable DHCP on them.
#>
Configuration Example
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
