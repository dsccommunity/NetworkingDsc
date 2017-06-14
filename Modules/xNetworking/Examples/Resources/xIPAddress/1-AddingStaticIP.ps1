<#
    .EXAMPLE
    Disabling DHCP and adding a static IP Address for IPv6
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

        xIPAddress NewIPAddress
        {
            IPAddress      = '2001:4898:200:7:6c71:a102:ebd8:f482/64'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV6'
        }

        # If no prefix is supplied then it will default to /24 for IPv4
        # IPv6 will default to /64.
        xIPAddress NewIPv4Address
        {
            IPAddress      = '192.168.10.5'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV4'
        }
    }
}
