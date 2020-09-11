configuration DSC_IPAddress_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        IPAddress Integration_Test {
            InterfaceAlias          = $Node.InterfaceAlias
            AddressFamily           = $Node.AddressFamily
            IPAddress               = $Node.IPAddress
        }
    }
}
