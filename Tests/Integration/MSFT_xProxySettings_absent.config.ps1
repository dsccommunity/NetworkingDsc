configuration MSFT_xProxySettings_Absent_Config {
    Import-DscResource -ModuleName xNetworking

    node localhost {
        xProxySettings Integration_Test {
            IsSingleInstance        = 'Yes'
            Ensure                  = 'Absent'
        }
    }
}
