<#
    .EXAMPLE
    Disable NetBios on Adapter
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName NetworkingDsc

    node $NodeName
    {
        NetBIOS DisableNetBIOS
        {
            InterfaceAlias = 'Ethernet'
            Setting        = 'Disable'
        }
    }
}
