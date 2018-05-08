$TestWeakHostReceive = [PSObject]@{
    InterfaceAlias = 'NetworkingDscLBA'
    AddressFamily  = 'IPv4'
    State          = 'Enabled'
}

configuration MSFT_WeakHostReceive_Config {
    Import-DscResource -ModuleName NetworkingDsc

    Node localhost {
        WeakHostReceive Integration_Test
        {
            InterfaceAlias = $TestWeakHostReceive.InterfaceAlias
            AddressFamily  = $TestWeakHostReceive.AddressFamily
            State          = $TestWeakHostReceive.State
        }
    }
}
