$TestEnableRscIPv6 = [PSObject]@{
    Name     = 'xNetworkingLBA'
    Protocol = 'IPv6'
    State    = $true
}

configuration MSFT_xNetAdapterRsc_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xNetAdapterRsc Integration_Test {
            Name        = $TestEnableRscIPv6.Name
            Protocol    = $TestEnableRscIPv6.Protocol
            State       = $TestEnableRscIPv6.State
        }
    }
}
