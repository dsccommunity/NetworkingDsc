<#
    .EXAMPLE
    Sets the Ethernet adapter to Private but does not change
    IPv4 or IPv6 connectivity
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
        NetConnectionProfile Example
        {
            InterfaceAlias   = 'Ethernet'
            NetworkCategory  = 'Private'
        }
    }
}
