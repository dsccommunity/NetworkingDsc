$TestAdapter = [PSObject]@{
    Name                    = 'SMB1_1'
    Enabled                 = $true
}

#This configuration enables RDMA setting on the network adapter.
configuration MSFT_xNetAdapterRDMA_Config
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking -Name xNetAdapterRDMA

    Node $NodeName
    {
        xNetAdapterRDMA SMB1
        {
          Name    = $TestAdapter.Name
          Enabled = $TestAdapter.Enabled
        }
    }
}
