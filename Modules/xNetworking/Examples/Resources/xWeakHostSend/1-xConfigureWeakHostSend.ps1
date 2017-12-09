<#
    .EXAMPLE
    Disabling tbe weak host send setting for the network adapter with alias 'Ethernet'.
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
            AddressFamily  = 'IPv4'
        }
    }
}
