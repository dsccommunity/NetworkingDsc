$TestTeam = [PSObject]@{
    Name                    = 'TestTeam'
    Members                 =  (Get-NetAdapter -Physical).Name
    loadBalancingAlgorithm  = 'Dynamic'
    teamingMode             = 'SwitchIndependent'
    Ensure                  = 'Absent'
}

configuration MSFT_NetworkTeam_Config
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
