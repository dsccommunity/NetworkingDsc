$TestIPAddress = [PSObject]@{
    InterfaceAlias          = 'NetworkingDscLBA'
    AddressFamily           = 'IPv4'
    IPAddress               = '10.11.12.13/16'
}

configuration MSFT_IPAddress_Config {
    Import-DscResource -ModuleName NetworkingDsc
    node localhost {
        xIPAddress Integration_Test {
            InterfaceAlias          = $TestIPAddress.InterfaceAlias
            AddressFamily           = $TestIPAddress.AddressFamily
            IPAddress               = $TestIPAddress.IPAddress
        }
    }
}
