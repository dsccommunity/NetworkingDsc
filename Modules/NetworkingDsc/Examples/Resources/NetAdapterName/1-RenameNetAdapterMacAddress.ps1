<#
    .EXAMPLE
    Rename three network adapters identified by MAC addresses to
    Cluster, Management and SMB and then enable DHCP on them.
#>
Configuration Example
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
