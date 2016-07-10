$DnsClientGlobalSetting = @{
    SuffixSearchList             = 'contoso.com'
    UseDevolution                = $True
    DevolutionLevel              = 1
}

Configuration MSFT_xDnsClientGlobalSetting_Config {
    Import-DscResource -ModuleName xDFS
    node localhost {
        xDnsClientGlobalSetting Integration_Test {
            IsSingleInstance     = 'Yes'
            SuffixSearchList     = $DnsClientGlobalSetting.SuffixSearchList
            UseDevolution        = $DnsClientGlobalSetting.UseDevolution
            DevolutionLevel      = $DnsClientGlobalSetting.DevolutionLevel
        }
    }
}
