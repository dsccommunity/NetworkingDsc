<#
    .EXAMPLE
    Disabling DHCP and adding a static IP Address for IPv6 and IPv4
    using default prefix lengths for the matching address classes
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module xNetworking

    Node $NodeName
    {
        xDhcpClient DisabledDhcpClient
        {
            State          = 'Disabled'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv6'
        }

        # If no prefix is supplied IPv6 will default to /64.
        xIPAddress NewIPv6Address
        {
            IPAddress      = '2001:4898:200:7:6c71:a102:ebd8:f482'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV6'
        }

        # If no prefix is supplied then IPv4 will default to class based:
        #  Class A - /8
        #  Class B - /16
        #  Class C - /24
        xIPAddress NewIPv4Address
        {
            IPAddress      = '192.168.10.5'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV4'
        }
    }
}
