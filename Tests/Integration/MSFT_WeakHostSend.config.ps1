$TestWeakHostSend = [PSObject]@{
    InterfaceAlias = 'NetworkingDscLBA'
    AddressFamily  = 'IPv4'
    State          = 'Enabled'
}

configuration MSFT_WeakHostSend_Config {
    Import-DscResource -ModuleName NetworkingDsc

    Node localhost {
        WeakHostSend Integration_Test
        {
            InterfaceAlias = $TestWeakHostSend.InterfaceAlias
            AddressFamily  = $TestWeakHostSend.AddressFamily
            State          = $TestWeakHostSend.State
        }
    }
}
