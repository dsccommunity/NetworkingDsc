configuration MSFT_xNetAdapterName_Config_NameOnly {
    Import-DscResource -ModuleName xNetworking

    node localhost {
        xNetAdapterName Integration_Test {
            Name                 = $Node.Name
            NewName              = $Node.NewName
        }
    }
}
