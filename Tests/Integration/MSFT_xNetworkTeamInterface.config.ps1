
configuration MSFT_xNetworkTeamInterface_Config
{
    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        xNetworkTeam HostTeam
        {
            Name                   = $Node.TeamName
            TeamingMode            = $Node.TeamingMode
            LoadBalancingAlgorithm = $Node.LoadBalancingAlgorithm
            TeamMembers            = $Node.Members
            Ensure                 = $Node.Ensure
        }

        xNetworkTeamInterface LbfoInterface
        {
            Name      = $Node.InterfaceName
            TeamName  = $Node.TeamName
            VlanID    = $Node.VlanId
            Ensure    = $Node.Ensure
            DependsOn = '[xNetworkTeam] HostTeam'
        }
    }
}
