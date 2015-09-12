configuration Sample_HostsFile
{
    Import-DscResource -Module xNetworking

    HostsFile HostsFileExample
    {
        IPAddress      = $IPAddress
        HostName       = $HostName
    }
}

Sample_HostsFile
