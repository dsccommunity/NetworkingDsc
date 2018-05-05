<#
    .EXAMPLE
    Rename three network adapters identified by MAC addresses to
    Cluster, Management and SMB and then enable DHCP on them.
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
            NewName    = 'Cluster'
            MacAddress = '9C-D2-1E-61-B5-DA'
        }

        DhcpClient EnableDhcpClientCluster
        {
            State          = 'Enabled'
            InterfaceAlias = 'Cluster'
            AddressFamily  = 'IPv4'
        }

        NetAdapterName RenameNetAdapterManagement
        {
            NewName    = 'Management'
            MacAddress = '9C-D2-1E-61-B5-DB'
        }

        DhcpClient EnableDhcpClientManagement
        {
            State          = 'Enabled'
            InterfaceAlias = 'Management'
            AddressFamily  = 'IPv4'
        }

        NetAdapterName RenameNetAdapterSMB
        {
            NewName    = 'SMB'
            MacAddress = '9C-D2-1E-61-B5-DC'
        }

        DhcpClient EnableDhcpClientSMB
        {
            State          = 'Enabled'
            InterfaceAlias = 'SMB'
            AddressFamily  = 'IPv4'
        }
    }
}
