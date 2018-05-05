configuration MSFT_DNSServerAddress_Config_DHCP {
    Import-DscResource -ModuleName NetworkingDsc
    node localhost {
        xDNSServerAddress Integration_Test {
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily
        }
    }
}
