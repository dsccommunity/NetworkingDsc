<#
    .EXAMPLE
    Enabling DHCP Client for the Ethernet Alias
#>
Configuration Example
{
    param
    (
        [string[] ]$NodeName = 'localhost'
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
