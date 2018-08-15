<#
    .EXAMPLE
    Add a new host with multiple IP addresses to the host file
#>
Configuration Example
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
        HostsFile HostEntry
        {
            HostName  = 'Host01'
            IPAddress = '192.168.0.1','192.168.0.1'
            Ensure    = 'Present'
        }
    }
}
