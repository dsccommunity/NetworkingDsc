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

    Import-DSCResource -ModuleName NetworkingDsc

    Node $NodeName
    {
        NetAdapterRss EnableRss
        {
            Name = 'Ethernet'
            Enabled = $True
        }
    }
}
