<#
    .EXAMPLE
    This configuration will set a DNS connection-specific suffix on a network interface that is identified by its alias.
#>
Configuration Example
{
    param
    (
        [string[]] $NodeName = 'localhost'
    )

    Import-DscResource -Module xNetworking
    Node $NodeName
    {
        xDnsConnectionSuffix DnsConnectionSuffix
        {
            InterfaceAlias           = 'Ethernet'
            ConnectionSpecificSuffix = 'contoso.com'
        }
    }
}
