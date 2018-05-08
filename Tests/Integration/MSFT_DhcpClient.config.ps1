$TestDhcpClient = [PSObject]@{
    InterfaceAlias = 'NetworkingDscLBA'
    AddressFamily  = 'IPv4'
    State          = 'Enabled'
}

configuration MSFT_DhcpClient_Config {
    Import-DscResource -ModuleName NetworkingDsc

    Node localhost {
        DhcpClient Integration_Test
        {
            InterfaceAlias = $TestDhcpClient.InterfaceAlias
            AddressFamily  = $TestDhcpClient.AddressFamily
            State          = $TestDhcpClient.State
        }
    }
}
