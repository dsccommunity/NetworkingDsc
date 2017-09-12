<#
    .EXAMPLE
    Disabling tbe weak host sending setting for the adapter with alias 'Ethernet'.
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
        xWeakHostSend DisableWeakHostSending
        {
            State          = 'Disabled'
            InterfaceAlias = 'Ethernet'
        }
    }
}
