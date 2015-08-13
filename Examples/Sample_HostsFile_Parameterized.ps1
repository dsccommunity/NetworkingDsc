configuration Sample_HostsFile_Parameterized
{
    param
    (

        [string[]]$NodeName = 'localhost',

        [Parameter(Mandatory)]
        [string]$IPAddress,

        [Parameter(Mandatory)]
        [string]$HostName
    )

    Import-DscResource -Module xNetworking

    Node $NodeName
    {
        HostsFile HostsFileExample
        {
            IPAddress      = $IPAddress
            HostName       = $HostName
        }
    }
}

Sample_HostsFile_Parameterized
