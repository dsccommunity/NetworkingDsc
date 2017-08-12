Configuration MSFT_xFirewallProfile_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xFirewallProfile Integration_Test {
            Name                            = $Node.Name
            Enabled                         = $Node.Enabled
            DefaultInboundAction            = $Node.DefaultInboundAction
            DefaultOutboundAction           = $Node.DefaultOutboundAction
            AllowInboundRules               = $Node.AllowInboundRules
            AllowLocalFirewallRules         = $Node.AllowLocalFirewallRules
            AllowLocalIPsecRules            = $Node.AllowLocalIPsecRules
            AllowUserApps                   = $Node.AllowUserApps
            AllowUserPorts                  = $Node.AllowUserPorts
            AllowUnicastResponseToMulticast = $Node.AllowUnicastResponseToMulticast
            NotifyOnListen                  = $Node.NotifyOnListen
            EnableStealthModeForIPsec       = $Node.EnableStealthModeForIPsec
            LogFileName                     = $Node.LogFileName
            LogMaxSizeKilobytes             = $Node.LogMaxSizeKilobytes
            LogAllowed                      = $Node.LogAllowed
            LogBlocked                      = $Node.LogBlocked
            LogIgnored                      = $Node.LogIgnored
            DisabledInterfaceAliases        = $Node.DisabledInterfaceAliases
        }
    }
}
