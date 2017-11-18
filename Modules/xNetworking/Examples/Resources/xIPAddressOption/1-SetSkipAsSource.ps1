<#
    .EXAMPLE
    Change the SkipAsSource option for a single IP address.
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
        xIPAddressOption SetSkipAsSource
        {
            IPAddress    = '192.168.10.5'
            SkipAsSource = $true
        }
    }
}
