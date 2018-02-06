Configuration MSFT_xWinsSetting_Config {
    Import-DscResource -ModuleName xNetworking

    node localhost {
        xWinsSetting Integration_Test
        {
            IsSingleInstance = 'Yes'
            EnableLmHosts    = $Node.EnableLmHosts
            EnableDns        = $Node.EnableDns
        }
    }
}
