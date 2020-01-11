configuration MSFT_WinsServerAddress_Config_Configured {

    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        WinsServerAddress Integration_Test {
            InterfaceAlias = $Node.InterfaceAlias
            Address        = $Node.Address
        }
    }
}
