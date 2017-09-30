configuration MSFT_xProxySettings_Present_Config {
    Import-DscResource -ModuleName xNetworking

    node localhost {
        xProxySettings Integration_Test {
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
