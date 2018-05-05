configuration MSFT_NetAdapterName_Config_NameOnly {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        xNetAdapterName Integration_Test {
            Name                 = $Node.Name
            NewName              = $Node.NewName
        }
    }
}
