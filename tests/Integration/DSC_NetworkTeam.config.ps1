
configuration DSC_NetworkTeam_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    node localhost
    {
        NetworkTeam HostTeam
        {
            Name                   = $Node.Name
            TeamingMode            = $Node.TeamingMode
            LoadBalancingAlgorithm = $Node.LoadBalancingAlgorithm
            TeamMembers            = $Node.Members
            Ensure                 = $Node.Ensure
        }
    }
}
