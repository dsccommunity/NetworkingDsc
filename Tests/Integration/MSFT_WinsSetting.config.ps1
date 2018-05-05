Configuration MSFT_WinsSetting_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        WinsSetting Integration_Test
        {
            IsSingleInstance = 'Yes'
            EnableLmHosts    = $Node.EnableLmHosts
            EnableDns        = $Node.EnableDns
        }
    }
}
