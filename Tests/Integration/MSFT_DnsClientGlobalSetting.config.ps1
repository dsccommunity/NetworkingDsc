Configuration MSFT_DnsClientGlobalSetting_Config {
    Import-DscResource -ModuleName NetworkingDsc
    node localhost {
        xDnsClientGlobalSetting Integration_Test {
            IsSingleInstance     = 'Yes'
            SuffixSearchList     = $Node.SuffixSearchList
            UseDevolution        = $Node.UseDevolution
            DevolutionLevel      = $Node.DevolutionLevel
        }
    }
}
