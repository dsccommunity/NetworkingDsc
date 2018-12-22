<#
    .EXAMPLE
    Disable the weak host send IPv4 setting for the network adapter with alias 'Ethernet'.
#>
Configuration Example
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface DisableWeakHostSend
        {
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            WeakHostSend   = 'Disable'
        }
    }
}
