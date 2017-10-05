<#
    .EXAMPLE
    This configuration disables RSS on the network adapter.
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
        xNetAdapterRss EnableRss
        {
            Name = 'Ethernet'
            Enabled = $True
        }
    }
}
