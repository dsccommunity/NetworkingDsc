$TestRoute = [PSObject]@{
    InterfaceAlias          = (Get-NetAdapter -Physical | Select-Object -First 1).Name
    AddressFamily           = 'IPv4'
    DestinationPrefix       = '10.0.0.0/8'
    NextHop                 = '10.0.1.0'
    Ensure                  = 'Present'
    RouteMetric             = 200
    Publish                 = 'No'
}

$route = Get-NetRoute | Select-Object -First 1

configuration MSFT_xRoute_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xRoute Integration_Test {
            InterfaceAlias          = $TestRoute.InterfaceAlias
            AddressFamily           = $TestRoute.AddressFamily
            DestinationPrefix       = $TestRoute.DestinationPrefix
            NextHop                 = $TestRoute.NextHop
            Ensure                  = $TestRoute.Ensure
            RouteMetric             = $TestRoute.RouteMetric
            Publish                 = $TestRoute.Publish
        }
    }
}
