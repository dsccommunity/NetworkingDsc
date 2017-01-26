<#
    .EXAMPLE
    Disable NetBios on Adapter
#>
configuration Example
{
    param
    (
        [string[]] $NodeName = 'localhost'
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
