
configuration MSFT_NetworkTeamInterface_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    node localhost
    {
        NetworkTeam HostTeam
        {
            Name                   = $Node.TeamName
            TeamingMode            = $Node.TeamingMode
            LoadBalancingAlgorithm = $Node.LoadBalancingAlgorithm
            TeamMembers            = $Node.Members
            Ensure                 = 'Present'
        }

        NetworkTeamInterface LbfoInterface
        {
            Name      = $Node.InterfaceName
            TeamName  = $Node.TeamName
            VlanID    = $Node.VlanId
            Ensure    = $Node.Ensure
            DependsOn = 'NetworkTeam]HostTeam'
        }
    }
}
