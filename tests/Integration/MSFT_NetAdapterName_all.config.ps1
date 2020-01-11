configuration MSFT_NetAdapterName_Config_All {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        NetAdapterName Integration_Test {
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
