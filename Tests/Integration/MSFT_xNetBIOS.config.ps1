$adapter = (Get-NetAdapter -Physical)[0]

configuration MSFT_xNetBIOS_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xNetBIOS Integration_Test {
            InterfaceAlias   = $adapter.Name
            Setting = 'Disable'
        }
    }
}