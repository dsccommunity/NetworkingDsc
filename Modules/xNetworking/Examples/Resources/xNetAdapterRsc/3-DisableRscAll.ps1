<#
    .EXAMPLE
    This configuration disables RSC on the network adapter.
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
            Protocol = 'All'
            State = $false
        }
    }
}
