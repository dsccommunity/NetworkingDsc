configuration MSFT_xNetAdapterRDMA_Config {
    Import-DSCResource -ModuleName xNetworking

    node localhost {
        xNetAdapterRDMA ConfigureRDMA {
            Name    = $Node.Name
            Enabled = $Node.Enabled
        }
    }
}
