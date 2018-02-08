configuration MSFT_xNetBIOS_Config {
    Import-DscResource -ModuleName xNetworking

    node localhost {
        xNetBIOS Integration_Test {
            InterfaceAlias      = $Node.InterfaceAlias
            Setting             = $Node.Setting
        }
    }
}
