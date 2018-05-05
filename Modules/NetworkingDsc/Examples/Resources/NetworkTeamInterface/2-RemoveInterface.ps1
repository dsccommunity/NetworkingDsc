<#
    .EXAMPLE
    Remove a Network Team Interface
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
        NetworkTeam HostTeam
        {
          Name = 'HostTeam'
          TeamingMode = 'SwitchIndependent'
          LoadBalancingAlgorithm = 'HyperVPort'
          TeamMembers = 'NIC1','NIC2'
          Ensure = 'Present'
        }

        NetworkTeamInterface NewInterface
        {
            Name = 'NewInterface'
            TeamName = 'HostTeam'
            Ensure = 'Absent'
            DependsOn = '[NetworkTeam]HostTeam'
        }
    }
}
