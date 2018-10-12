<#
    .EXAMPLE
    This example enables the following settings on the IPv4 network interface with alias
    'Ethernet':
    - AdvertiseDefaultRoute
    - Avertising
    - AutomaticMetric
    - Forwarding
    - IgnoreDefaultRoute
#>
Configuration Example
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface EnableSettings
        {
            InterfaceAlias        = 'Ethernet'
            AddressFamily         = 'IPv4'
            AdvertiseDefaultRoute = 'Enabled'
            Advertising           = 'Enabled'
            AutomaticMetric       = 'Enabled'
            Forwarding            = 'Enabled'
            IgnoreDefaultRoutes   = 'Enabled'
        }
    }
}
