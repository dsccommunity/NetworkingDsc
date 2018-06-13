<#
    .EXAMPLE
    Add New Network Team Interface
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
            VlanID = 100
            Ensure = 'Present'
            DependsOn = '[NetworkTeam]HostTeam'
        }
    }
}
