Configuration MSFT_xDnsClientGlobalSetting_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xDnsClientGlobalSetting Integration_Test {
            IsSingleInstance     = 'Yes'
            SuffixSearchList     = $Node.SuffixSearchList
            UseDevolution        = $Node.UseDevolution
            DevolutionLevel      = $Node.DevolutionLevel
        }
    }
}
