<#
    .EXAMPLE
    This configuration disables RDMA setting on the network adapter.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName NetworkingDsc

    Node $NodeName
    {
        NetAdapterRdma SMBAdapter1
        {
            Name = 'SMB1_1'
            Enabled = $false
        }
    }
}
