#This configuration disables RDMA setting on the network adapter.
configuration Sample_xNetAdapterRDMA_Disable
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
          Enabled = $false
        }
    }
 }

Sample_xNetAdapterRDMA_Disable
Start-DscConfiguration -Path Sample_xNetAdapterRDMA_Disable -Wait -Verbose -Force
