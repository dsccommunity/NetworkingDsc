<#
    .EXAMPLE
    Disabling DHCP and adding multiple static IP Addresses for IPv6
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
            IPAddress      = '2001:4898:200:7:6c71:a102:ebd8:f482/64','2001:4598:210:7:6d71:a102:ebe8:f483/64'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPV6'
        }
    }
}
