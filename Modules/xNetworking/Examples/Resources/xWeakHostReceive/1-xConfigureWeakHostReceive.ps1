<#
    .EXAMPLE
    Disabling tbe weak host receiving setting for the adapter with alias 'Ethernet'.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module xNetworking

    Node $NodeName
    {
        xWeakHostSend DisableWeakHostReceiving
        {
            State          = 'Disabled'
            InterfaceAlias = 'Ethernet'
        }
    }
}
