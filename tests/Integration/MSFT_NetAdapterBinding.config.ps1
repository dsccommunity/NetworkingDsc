$TestDisableIPv4 = [PSObject]@{
    InterfaceAlias = 'NetworkingDscLBA'
    ComponentId    = 'ms_tcpip'
    State          = 'Disabled'
}

configuration MSFT_NetAdapterBinding_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        NetAdapterBinding Integration_Test
        {
            InterfaceAlias = $TestDisableIPv4.InterfaceAlias
            ComponentId    = $TestDisableIPv4.ComponentId
            State          = $TestDisableIPv4.State
        }
    }
}
