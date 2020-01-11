configuration MSFT_DnsServerAddress_Config_DHCP {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        DnsServerAddress Integration_Test {
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily
        }
    }
}
