<#
    .EXAMPLE
    Configure fabrikam.com and fourthcoffee.com for the DNS SuffixSearchList
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
        DnsClientGlobalSetting AddMultipleDNSSuffix
        {
            IsSingleInstance = 'Yes'
            SuffixSearchList = ('fabrikam.com', 'fourthcoffee.com')
            UseDevolution    = $true
            DevolutionLevel  = 0
        }
    }
}
