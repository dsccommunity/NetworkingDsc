$TestDefaultGatewayAddress = [PSObject]@{
    InterfaceAlias = 'NetworkingDscLBA'
    AddressFamily  = 'IPv4'
    Address        = '10.0.0.0'
}

configuration MSFT_DefaultGatewayAddress_Config {
    Import-DscResource -ModuleName NetworkingDsc

    Node localhost {
        xDefaultGatewayAddress Integration_Test
        {
            InterfaceAlias = $TestDefaultGatewayAddress.InterfaceAlias
            AddressFamily  = $TestDefaultGatewayAddress.AddressFamily
            Address        = $TestDefaultGatewayAddress.Address
        }
    }
}
