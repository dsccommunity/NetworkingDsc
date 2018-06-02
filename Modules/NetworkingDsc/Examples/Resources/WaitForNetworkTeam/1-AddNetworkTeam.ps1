<#
    .EXAMPLE
    Creates the switch independent Network Team 'HostTeam' using the NIC1
    and NIC2 interfaces. It sets the load balacing algorithm to 'HyperVPort'.
    The config will then wait for the 'HostTeam' to achieve the 'Up' status.
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
            Name                   = 'HostTeam'
            TeamingMode            = 'SwitchIndependent'
            LoadBalancingAlgorithm = 'HyperVPort'
            TeamMembers            = 'NIC1', 'NIC2'
            Ensure                 = 'Present'
        }

        WaitForNetworkTeam WaitForHostTeam
        {
            Name      = 'HostTeam'
            DependsOn = '[NetworkTeam]HostTeam'
        }
    }
}
