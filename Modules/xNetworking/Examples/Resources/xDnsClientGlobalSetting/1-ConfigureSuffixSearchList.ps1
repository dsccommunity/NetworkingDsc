<#
    .EXAMPLE
    Configure only contoso.com for the DNS Suffix
#>
Configuration Example
{
    param
    (
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module xNetworking

    Node $NodeName
    {
        xDnsClientGlobalSetting AddDNSSuffix
        {
            IsSingleInstance = 'Yes'
            SuffixSearchList = 'contoso.com'
            UseDevolution    = $true
            DevolutionLevel  = 0
        }
    }
}
