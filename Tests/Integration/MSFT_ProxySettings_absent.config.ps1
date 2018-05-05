configuration MSFT_ProxySettings_Absent_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        xProxySettings Integration_Test {
            IsSingleInstance        = 'Yes'
            Ensure                  = 'Absent'
        }
    }
}
