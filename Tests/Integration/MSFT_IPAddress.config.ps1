$TestIPAddress = [PSObject]@{
    InterfaceAlias          = 'NetworkingDscLBA'
    AddressFamily           = 'IPv4'
    IPAddress               = '10.11.12.13/16'
}
$TestMultipleIPAddress = [PSObject]@{
    InterfaceAlias          = 'NetworkingDscLBA2'
    AddressFamily           = 'IPv4'
    IPAddress               = @('10.12.13.14/16','10.13.14.16/32')
}

configuration MSFT_IPAddress_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        IPAddress Integration_Test {
            InterfaceAlias          = $TestIPAddress.InterfaceAlias
            AddressFamily           = $TestIPAddress.AddressFamily
            IPAddress               = $TestIPAddress.IPAddress
        }
        IPAddress Integration_Test2 {
            InterfaceAlias          = $TestMultipleIPAddress.InterfaceAlias
            AddressFamily           = $TestMultipleIPAddress.AddressFamily
            IPAddress               = $TestMultipleIPAddress.IPAddress
        }
    }
}
