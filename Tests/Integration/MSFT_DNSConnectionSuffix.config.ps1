$TestDnsConnectionSuffix = [PSObject]@{
    InterfaceAlias                 = 'NetworkingDscLBA'
    ConnectionSpecificSuffix       = 'contoso.com'
    RegisterThisConnectionsAddress = $true
    UseSuffixWhenRegistering       = $false
    Ensure                         = 'Present'
}

configuration MSFT_DnsConnectionSuffix_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        DnsConnectionSuffix Integration_Test {
            InterfaceAlias                 = $TestDnsConnectionSuffix.InterfaceAlias
            ConnectionSpecificSuffix       = $TestDnsConnectionSuffix.ConnectionSpecificSuffix
            RegisterThisConnectionsAddress = $TestDnsConnectionSuffix.RegisterThisConnectionsAddress
            UseSuffixWhenRegistering       = $TestDnsConnectionSuffix.UseSuffixWhenRegistering
            Ensure                         = $TestDnsConnectionSuffix.Ensure
        }
    }
}
