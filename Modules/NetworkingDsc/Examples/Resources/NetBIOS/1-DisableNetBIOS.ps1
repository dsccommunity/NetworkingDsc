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
        xNetBIOS DisableNetBIOS
        {
            InterfaceAlias = 'Ethernet'
            Setting        = 'Disable'
        }
    }
}
