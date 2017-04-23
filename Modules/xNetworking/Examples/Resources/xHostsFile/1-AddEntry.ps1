<#
    .EXAMPLE
    Add a new host to the host file
#>
Configuration Example
{
    param
    (
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xHostsFile HostEntry
        {
            HostName  = 'Host01'
            IPAddress = '192.168.0.1'
            Ensure    = 'Present'
        }
    }
}
