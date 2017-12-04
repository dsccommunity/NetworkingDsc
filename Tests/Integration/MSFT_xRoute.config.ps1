configuration MSFT_xRoute_Config {
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName xNetworking

    Node $NodeName {
        xRoute Integration_Test {
            InterfaceAlias          = $Node.InterfaceAlias
            AddressFamily           = $Node.AddressFamily
            DestinationPrefix       = $Node.DestinationPrefix
            NextHop                 = $Node.NextHop
            Ensure                  = $Node.Ensure
            RouteMetric             = $Node.RouteMetric
            Publish                 = $Node.Publish
        }
    }
}
