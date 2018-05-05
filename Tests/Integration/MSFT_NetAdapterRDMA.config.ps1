configuration MSFT_NetAdapterRDMA_Config {
    Import-DSCResource -ModuleName NetworkingDsc

    node localhost {
        NetAdapterRDMA ConfigureRDMA {
            Name    = $Node.Name
            Enabled = $Node.Enabled
        }
    }
}
