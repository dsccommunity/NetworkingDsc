<#
    .EXAMPLE
    This configuration disables RDMA setting on the network adapter.
#>

configuration Example
{
    param
    (
        [string[]] $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xNetAdapterRDMA SMBAdapter1
        {
            Name = 'SMB1_1'
            Enabled = $false
        }
    }
 }
