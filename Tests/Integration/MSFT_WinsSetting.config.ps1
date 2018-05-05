Configuration MSFT_WinsSetting_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        xWinsSetting Integration_Test
        {
            IsSingleInstance = 'Yes'
            EnableLmHosts    = $Node.EnableLmHosts
            EnableDns        = $Node.EnableDns
        }
    }
}
