Configuration MSFT_xHostsFile_Config
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
        xHostsFile HostEntry
        {
            HostName  = $Node.HostName
            IPAddress = $Node.IPAddress
            Ensure    = $Node.Ensure
        }
    }
}
