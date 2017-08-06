configuration MSFT_xDNSServerAddress_Config_Static {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xDNSServerAddress Integration_Test {
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily
            Address        = $Node.Address
            Validate       = $Node.Validate
        }
    }
}
