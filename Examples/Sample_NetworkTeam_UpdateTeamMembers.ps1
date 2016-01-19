configuration Sample_NetworkTeam_UpdateTeamMembers
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
          Name = 'HostTeam'
          TeamingMode = 'SwitchIndependent'
          LoadBalancingAlgorithm = 'HyperVPort'
          TeamMembers = 'NIC1','NIC2','NIC3'
          Ensure = 'Present'
        }
    }
 }

Sample_NetworkTeam_UpdateTeamMembers
Start-DscConfiguration -Path Sample_NetworkTeam_UpdateTeamMembers -Wait -Verbose -Force
