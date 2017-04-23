<#
    .EXAMPLE
    Disable NetBios on Adapter
#>
Configuration Example
{
    param
    (
        [string[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName xNetworking

    node $NodeName 
    {
        xNetBIOS DisableNetBIOS 
        {
            InterfaceAlias = 'Ethernet'
            Setting        = 'Disable'
        }
    }
}
