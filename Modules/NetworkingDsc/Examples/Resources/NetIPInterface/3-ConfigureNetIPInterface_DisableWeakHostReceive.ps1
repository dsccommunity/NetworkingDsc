<#
    .EXAMPLE
    Disable the weak host receive IPv4 setting for the network adapter with alias 'Ethernet'.
#>
Configuration Example
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface DisableWeakHostReceiving
        {
            InterfaceAlias  = 'Ethernet'
            AddressFamily   = 'IPv4'
            WeakHostReceive = 'Disable'
        }
    }
}
