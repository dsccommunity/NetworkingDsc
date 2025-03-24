Configuration DSC_DnsClientNrptGlobal_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        DnsClientNrptGlobal Integration_Test {
            IsSingleInstance     = 'Yes'
            EnableDAForAllNetworks  = $Node.EnableDAForAllNetworks
            QueryPolicy             = $Node.QueryPolicy
            SecureNameQueryFallback = $Node.SecureNameQueryFallback
        }
    }
}
