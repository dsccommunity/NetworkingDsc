$TestWeakHostReceive = [PSObject]@{
    InterfaceAlias = 'xNetworkingLBA'
    AddressFamily  = 'IPv4'
    State          = 'Enabled'
}

configuration MSFT_xWeakHostReceive_Config {
    Import-DscResource -ModuleName xNetworking

    Node localhost {
        xWeakHostReceive Integration_Test
        {
            InterfaceAlias = $TestWeakHostReceive.InterfaceAlias
            AddressFamily  = $TestWeakHostReceive.AddressFamily
            State          = $TestWeakHostReceive.State
        }
    }
}
