<#
    .EXAMPLE
    This configuration disables LSO for IPv6 on the network adapter.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName NetworkingDsc

    Node $NodeName
    {
        NetAdapterLso DisableLsoIPv6
        {
            Name     = 'Ethernet'
            Protocol = 'IPv6'
            State    = $false
        }
    }
}
