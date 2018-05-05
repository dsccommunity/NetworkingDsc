configuration MSFT_DNSServerAddress_Config_Static {
    Import-DscResource -ModuleName NetworkingDsc
    node localhost {
        xDNSServerAddress Integration_Test {
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily
            Address        = $Node.Address
            Validate       = $Node.Validate
        }
    }
}
