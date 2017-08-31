<#
    .EXAMPLE
    This configuration disables RSC for IPv4 on the network adapter.
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
        xNetAdapterRsc DisableRscIPv4
        {
            Name = 'Ethernet'
            Protocol = 'IPv4'
            State = $false
        }
    }
}
