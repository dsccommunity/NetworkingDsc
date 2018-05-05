configuration MSFT_NetBIOS_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        NetBIOS Integration_Test {
            InterfaceAlias      = $Node.InterfaceAlias
            Setting             = $Node.Setting
        }
    }
}
