configuration DSC_Route_Config {
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName NetworkingDsc

    Node $NodeName {
        Route Integration_Test {
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
