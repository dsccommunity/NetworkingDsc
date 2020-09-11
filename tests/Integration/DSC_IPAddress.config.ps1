configuration DSC_IPAddress_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        IPAddress Integration_Test {
            InterfaceAlias          = $TestIPAddress.InterfaceAlias
            AddressFamily           = $TestIPAddress.AddressFamily
            IPAddress               = $TestIPAddress.IPAddress
        }
    }
}
