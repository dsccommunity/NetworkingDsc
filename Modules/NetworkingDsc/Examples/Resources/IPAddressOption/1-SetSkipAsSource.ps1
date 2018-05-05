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

    Import-DscResource -Module NetworkingDsc

    Node $NodeName
    {
        IPAddressOption SetSkipAsSource
        {
            IPAddress    = '192.168.10.5'
            SkipAsSource = $true
        }
    }
}
