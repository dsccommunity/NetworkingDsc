$TestIPAddress = [PSObject]@{
    InterfaceAlias          = 'NetworkingDscLBA'
    AddressFamily           = 'IPv4'
    IPAddress               = '10.11.12.13/16'
}
$TestIPAddressOption = [PSObject]@{
    IPAddress    = '10.11.12.13'
    SkipAsSource = $true
}

configuration DSC_IPAddressOption_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        IPAddress Integration_Test {
            InterfaceAlias = $TestIPAddress.InterfaceAlias
            AddressFamily  = $TestIPAddress.AddressFamily
            IPAddress      = $TestIPAddress.IPAddress
        }

        IPAddressOption Integration_Test {
            IPAddress    = $TestIPAddressOption.IPAddress
            SkipAsSource = $TestIPAddressOption.SkipAsSource
        }
    }
}
