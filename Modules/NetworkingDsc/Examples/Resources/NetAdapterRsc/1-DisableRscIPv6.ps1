<#
    .EXAMPLE
    This configuration disables RSC for IPv6 on the network adapter.
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
        NetAdapterRsc DisableRscIPv6
        {
            Name = 'Ethernet'
            Protocol = 'IPv6'
            State = $false
        }
    }
}
