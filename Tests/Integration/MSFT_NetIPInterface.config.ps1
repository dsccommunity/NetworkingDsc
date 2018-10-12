configuration MSFT_NetIPInterface_Config_Enabled {
    Import-DscResource -ModuleName NetworkingDsc

    Node localhost {
        NetIPInterface Integration_Test
        {
            InterfaceAlias        = $Node.InterfaceAlias
            AddressFamily         = $Node.AddressFamily
            AdvertiseDefaultRoute = $Node.AdvertiseDefaultRoute
            AutomaticMetric       = $Node.AutomaticMetric
            Forwarding            = $Node.Forwarding
            IgnoreDefaultRoutes   = $Node.IgnoreDefaultRoutes
        }
    }
}

configuration MSFT_NetIPInterface_Config_Disabled {
    Import-DscResource -ModuleName NetworkingDsc

    Node localhost {
        NetIPInterface Integration_Test
        {
            InterfaceAlias        = $Node.InterfaceAlias
            AddressFamily         = $Node.AddressFamily
            AdvertiseDefaultRoute = $Node.AdvertiseDefaultRoute
            Forwarding            = $Node.Forwarding
            IgnoreDefaultRoutes   = $Node.IgnoreDefaultRoutes
        }
    }
}
