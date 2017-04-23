<#
    .EXAMPLE
    Enabling DHCP Client for the Ethernet Alias
#>
Configuration Example
{
    param
    (
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module xNetworking

    Node $NodeName
    {
        xDhcpClient EnableDhcpClient
        {
            State          = 'Enabled'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }
    }
}
