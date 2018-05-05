Configuration MSFT_HostsFile_Config
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
        xHostsFile HostEntry
        {
            HostName  = $Node.HostName
            IPAddress = $Node.IPAddress
            Ensure    = $Node.Ensure
        }
    }
}
