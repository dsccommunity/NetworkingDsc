<#
    .EXAMPLE
    Set the IPv4 default gateway of the network interface 'Ethernet'
    to '192.168.1.1'.

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
        xDefaultGatewayAddress SetDefaultGateway
        {
            Address        = '192.168.1.1'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }
    }
}
