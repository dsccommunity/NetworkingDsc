<#
    .EXAMPLE
    Sets the computer to use a manually configured proxy server
    with the address 'proxy.contoso.com' on port 8888. Traffic to addresses
    starting with 'web1' or 'web2' or any local addresses will not be sent
    to the proxy.
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
        xProxySettings ManualProxy
        {
            IsSingleInstance        = 'Yes'
            Ensure                  = 'Present'
            EnableAutoDetection     = $false
            EnableAutoConfiguration = $false
            EnableManualProxy       = $true
            ProxyServer             = 'proxy.contoso.com:8888'
            ProxyServerExceptions   = 'web1', 'web2'
            ProxyServerBypassLocal  = $true
        }
    }
}
