$TestIPAddress = [PSObject]@{
    InterfaceAlias          = 'xNetworkingLBA'
    AddressFamily           = 'IPv4'
    IPAddress               = '10.11.12.13/16'
}
$TestIPAddressOption = [PSObject]@{
    IPAddress    = '10.11.12.13'
    SkipAsSource = 'True'
}

configuration MSFT_xIPAddressOption_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xIPAddress Integration_Test {
            InterfaceAlias = $TestIPAddress.InterfaceAlias
            AddressFamily  = $TestIPAddress.AddressFamily
            IPAddress      = $TestIPAddress.IPAddress
        }
        xIPAddressOption Integration_Test {
            IPAddress    = $TestIPAddressOption.IPAddress
            SkipAsSource = $TestIPAddressOption.SkipAsSource
        }
    }
}
