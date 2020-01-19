configuration DSC_ProxySettings_Absent_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        ProxySettings Integration_Test {
            IsSingleInstance        = 'Yes'
            Ensure                  = 'Absent'
        }
    }
}
