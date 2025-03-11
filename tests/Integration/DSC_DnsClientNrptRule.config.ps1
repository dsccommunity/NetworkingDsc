configuration DSC_DnsClientNrptRule_Config {
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName NetworkingDsc

    Node $NodeName {
        DnsClientNrptRule Integration_Test {
            Name         = $Node.Name
            Namespace    = $Node.Namespace
            NameEncoding = $Node.NameEncoding
            NameServers  = $Node.NameServers
        }
    }
}
