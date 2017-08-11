configuration MSFT_xDNSServerAddress_Config_DHCP {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xDNSServerAddress Integration_Test {
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily
        }
    }
}
