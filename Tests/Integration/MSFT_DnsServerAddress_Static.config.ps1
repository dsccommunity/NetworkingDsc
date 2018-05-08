configuration MSFT_DnsServerAddress_Config_Static {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        DnsServerAddress Integration_Test {
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily
            Address        = $Node.Address
            Validate       = $Node.Validate
        }
    }
}
