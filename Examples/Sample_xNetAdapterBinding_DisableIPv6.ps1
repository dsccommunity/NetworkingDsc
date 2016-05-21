configuration Sample_xNetAdapterBinding_DisableIPv6
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xNetAdapterBinding DisableIPv6
        {
            InterfaceAlias = 'Ethernet'
            ComponentId = 'ms_tcpip6'
            EnsureEnabled = 'Disabled'
        }
    }
}

Sample_xNetAdapterBinding_DisableIPv6
Start-DscConfiguration -Path Sample_xNetAdapterBinding_DisableIPv6 -Wait -Verbose -Force
