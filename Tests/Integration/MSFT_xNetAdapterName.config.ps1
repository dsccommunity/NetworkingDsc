configuration MSFT_xNetAdapterName_Config {
    Import-DscResource -ModuleName xNetworking

    node localhost {
        xNetAdapterName Integration_Test {
            Name                 = $Node.Name
            NewName              = $Node.NewName
            PhysicalMediaType    = $Node.PhysicalMediaType
            Status               = $Node.Status
            MacAddress           = $Node.MacAddress
            InterfaceDescription = $Node.InterfaceDescription
            InterfaceIndex       = $Node.InterfaceIndex
            InterfaceGuid        = $Node.InterfaceGuid
        }
    }
}
