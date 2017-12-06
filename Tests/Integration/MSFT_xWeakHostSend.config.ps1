$TestWeakHostSend = [PSObject]@{
    InterfaceAlias = 'xNetworkingLBA'
    AddressFamily  = 'IPv4'
    State          = 'Enabled'
}

configuration MSFT_xWeakHostSend_Config {
    Import-DscResource -ModuleName xNetworking

    Node localhost {
        xWeakHostSend Integration_Test
        {
            InterfaceAlias = $TestWeakHostSend.InterfaceAlias
            AddressFamily  = $TestWeakHostSend.AddressFamily
            State          = $TestWeakHostSend.State
        }
    }
}
