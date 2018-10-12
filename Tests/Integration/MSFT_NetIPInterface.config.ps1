configuration MSFT_NetIPInterface_Config_Enabled {
    Import-DscResource -ModuleName NetworkingDsc

    Node localhost {
        NetIPInterface Integration_Test
        {
            InterfaceAlias        = $Node.InterfaceAlias
            AddressFamily         = $Node.AddressFamily
            AdvertiseDefaultRoute = $Node.AdvertiseDefaultRoute
            AutomaticMetric       = $Node.AutomaticMetric
            DirectedMacWolPattern = $Node.DirectedMacWolPattern
            EcnMarking            = $Node.EcnMarking
            ForceArpNdWolPattern  = $Node.ForceArpNdWolPattern
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
            DirectedMacWolPattern = $Node.DirectedMacWolPattern
            EcnMarking            = $Node.EcnMarking
            ForceArpNdWolPattern  = $Node.ForceArpNdWolPattern
            Forwarding            = $Node.Forwarding
            IgnoreDefaultRoutes   = $Node.IgnoreDefaultRoutes
        }
    }
}
