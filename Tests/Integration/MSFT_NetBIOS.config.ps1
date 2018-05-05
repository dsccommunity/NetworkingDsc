configuration MSFT_NetBIOS_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        xNetBIOS Integration_Test {
            InterfaceAlias      = $Node.InterfaceAlias
            Setting             = $Node.Setting
        }
    }
}
