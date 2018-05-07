configuration MSFT_NetAdapterRdma_Config {
    Import-DSCResource -ModuleName NetworkingDsc

    node localhost {
        NetAdapterRdma ConfigureRDMA {
            Name    = $Node.Name
            Enabled = $Node.Enabled
        }
    }
}
