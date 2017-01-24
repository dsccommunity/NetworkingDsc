$HostEntry = [PSObject] @{
    HostName      = 'Host01'
    IPAddress     = '192.168.0.1'
    Ensure        = 'Absent'
}

Configuration MSFT_xHostsFile_Config_Remove
{
    param
    (
        [string[]] $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xHostsFile HostEntry
        {
          HostName    = $HostEntry.HostName
          IPAddress   = $HostEntry.IPAddress
          Ensure      = $HostEntry.Ensure
        }
    }
}
