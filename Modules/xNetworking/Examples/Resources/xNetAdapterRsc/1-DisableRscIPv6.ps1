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

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xNetAdapterRsc DisableRscIPv6
        {
            Name = 'Ethernet'
            Protocol = 'IPv6'
            State = $false
        }
    }
}
