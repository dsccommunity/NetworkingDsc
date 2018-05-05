<#
    .EXAMPLE
    Rename the first three network adapters with Driver Description matching
    'Hyper-V Virtual Ethernet Adapter' in consequtive order to Cluster, Management
    and SMB and then enable DHCP on them.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName NetworkingDsc

    Node $NodeName
    {
        NetAdapterName RenameNetAdapterCluster
        {
            NewName           = 'Cluster'
            DriverDescription = 'Hyper-V Virtual Ethernet Adapter'
            InterfaceNumber   = 1
        }

        DhcpClient EnableDhcpClientCluster
        {
            State          = 'Enabled'
            InterfaceAlias = 'Cluster'
            AddressFamily  = 'IPv4'
        }

        NetAdapterName RenameNetAdapterManagement
        {
            NewName           = 'Management'
            DriverDescription = 'Hyper-V Virtual Ethernet Adapter'
            InterfaceNumber   = 2
        }

        DhcpClient EnableDhcpClientManagement
        {
            State          = 'Enabled'
            InterfaceAlias = 'Management'
            AddressFamily  = 'IPv4'
        }

        NetAdapterName RenameNetAdapterSMB
        {
            NewName           = 'SMB'
            DriverDescription = 'Hyper-V Virtual Ethernet Adapter'
            InterfaceNumber   = 3
        }

        DhcpClient EnableDhcpClientSMB
        {
            State          = 'Enabled'
            InterfaceAlias = 'SMB'
            AddressFamily  = 'IPv4'
        }
    }
}
