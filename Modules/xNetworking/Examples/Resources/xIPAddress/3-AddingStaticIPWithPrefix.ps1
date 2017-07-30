<#
    .EXAMPLE
    Disabling DHCP and adding a static IP Address for IPv6 and IPv4
    using specified prefixes in CIDR notation.
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

        xIPAddress NewIPv6Address
        {
            IPAddress      = '2001:4898:200:7:6c71:a102:ebd8:f482/64'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV6'
        }

        xIPAddress NewIPv4Address
        {
            IPAddress      = '192.168.10.5/24'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV4'
        }
    }
}
