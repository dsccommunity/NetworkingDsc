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
        NetBios DisableNetBios
        {
            InterfaceAlias = 'Ethernet'
            Setting        = 'Disable'
        }
    }
}
