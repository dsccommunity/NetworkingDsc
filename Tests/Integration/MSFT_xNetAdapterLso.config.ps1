$TestDisableLsoIPv6 = [PSObject]@{
    Name     = 'xNetworkingLBA'
    Protocol = 'IPv6'
    State    = $false
}

configuration MSFT_xNetAdapterLso_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xNetAdapterLso Integration_Test {
            Name        = $TestDisableLsoIPv6.Name
            Protocol    = $TestDisableLsoIPv6.Protocol
            State       = $TestDisableLsoIPv6.StStateate
        }
    }
}
