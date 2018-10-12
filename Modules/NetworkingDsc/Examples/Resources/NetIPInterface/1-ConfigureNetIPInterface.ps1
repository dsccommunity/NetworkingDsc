<#
    .EXAMPLE
    This example enables the following settings on the IPv4 network interface with alias
    'Ethernet':
    - AdvertiseDefaultRoute
    - Avertising
    - AutomaticMetric
    - DirectedMacWolPattern
    - ForceArpNdWolPattern
    - Forwarding
    - IgnoreDefaultRoute
    The EcnMarking parameter will be set to AppDecide.
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
            DirectedMacWolPattern = 'Enabled'
            EcnMarking            = 'AppDecide'
            ForceArpNdWolPattern  = 'Enabled'
            Forwarding            = 'Enabled'
            IgnoreDefaultRoutes   = 'Enabled'
        }
    }
}
