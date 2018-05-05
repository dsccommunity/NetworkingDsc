configuration MSFT_NetAdapterRDMA_Config {
    Import-DSCResource -ModuleName NetworkingDsc

    node localhost {
        xNetAdapterRDMA ConfigureRDMA {
            Name    = $Node.Name
            Enabled = $Node.Enabled
        }
    }
}
