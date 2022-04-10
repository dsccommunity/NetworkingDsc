configuration DSC_NetAdapterLso_Config {
    Import-DscResource -ModuleName NetworkingDsc

    node localhost {
        NetAdapterLso Integration_Test
        {
            Name     = $Node.Name
            Protocol = $Node.Protocol
            State    = $Node.State
        }
    }
}
