$TestAdapter = [PSObject]@{
    Name                    = 'SMB1_1'
    Enabled                 = $true
}

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
