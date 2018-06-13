configuration MSFT_NetBios_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        NetBios Integration_Test {
            InterfaceAlias      = $Node.InterfaceAlias
            Setting             = $Node.Setting
        }
    }
}
