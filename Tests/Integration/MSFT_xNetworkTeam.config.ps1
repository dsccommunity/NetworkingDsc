
configuration MSFT_xNetworkTeam_Config
{
    Import-DSCResource -ModuleName xNetworking

    node localhost
    {
        xNetworkTeam HostTeam
        {
            Name                   = $Node.Name
            TeamingMode            = $Node.TeamingMode
            LoadBalancingAlgorithm = $Node.LoadBalancingAlgorithm
            TeamMembers            = $Node.Members
            Ensure                 = $Node.Ensure
        }
    }
}
