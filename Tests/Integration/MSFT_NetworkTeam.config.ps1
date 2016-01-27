$TestTeam = [PSObject]@{
    Name                    = 'TestTeam'
    Members                 =  (Get-NetAdapter -Physical).Name
    loadBalancingAlgorithm  = 'Dynamic'
    teamingMode             = 'SwitchIndependent'
    Ensure                  = 'Present'
}

configuration Sample_NetworkTeam_AddTeam
{
    param
    (
        [string[]]$NodeName = 'localhost'
    )

    Import-DSCResource -ModuleName xNetworking

    Node $NodeName
    {
        NetworkTeam HostTeam
        {
          Name = $TestTeam.Name
          TeamingMode = $TestTeam.teamingMode
          LoadBalancingAlgorithm = $TestTeam.loadBalancingAlgorithm
          TeamMembers = $TestTeam.Members
          Ensure = 'Present'
        }
    }
}
