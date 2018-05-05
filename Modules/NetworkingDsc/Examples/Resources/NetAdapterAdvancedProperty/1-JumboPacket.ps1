<#
    .EXAMPLE
    This configuration changes the JumboPacket Size.
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
        xNetAdapterAdvancedProperty JumboPacket9014
        {
            NetworkAdapterName  = 'Ethernet'
            RegistryKeyword     = "*JumboPacket"
            RegistryValue       = 9014
        }
    }
}
