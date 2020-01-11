configuration MSFT_ProxySettings_Present_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        ProxySettings Integration_Test {
            IsSingleInstance        = 'Yes'
            Ensure                  = 'Present'
            EnableAutoDetection     = $Node.EnableAutoDetection
            EnableAutoConfiguration = $Node.EnableAutoConfiguration
            EnableManualProxy       = $Node.EnableManualProxy
            ProxyServer             = $Node.ProxyServer
            ProxyServerExceptions   = $Node.ProxyServerExceptions
            ProxyServerBypassLocal  = $Node.ProxyServerBypassLocal
            AutoConfigURL           = $Node.AutoConfigURL
        }
    }
}
