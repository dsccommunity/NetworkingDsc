#This configuration enables RDMA setting on the network adapter.
configuration Sample_xNetAdapterRDMA_Enable
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking -Name xNetAdapterRDMA

    Node $NodeName
    {
        xNetAdapterRDMA SMBAdapter1
        {
          Name = 'SMB1_1'
          Enabled = $true
        }
    }
 }

Sample_xNetAdapterRDMA_Enable
Start-DscConfiguration -Path Sample_xNetAdapterRDMA_Enable -Wait -Verbose -Force
