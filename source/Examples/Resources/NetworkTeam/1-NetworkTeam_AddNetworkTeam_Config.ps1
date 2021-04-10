<#PSScriptInfo
.VERSION 1.0.0
.GUID 1b89dde9-d835-4941-900c-fa99ccbe42d1
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/NetworkingDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/NetworkingDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module NetworkingDsc

<#
    .DESCRIPTION
    Creates the switch independent Network Team 'HostTeam' using the NIC1
    and NIC2 interfaces. It sets the load balacing algorithm to 'HyperVPort'.
    The config will then wait for the 'HostTeam' to achieve the 'Up' status.
#>
Configuration NetworkTeam_AddNetworkTeam_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetworkTeam AddNetworkTeam
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
            DependsOn = '[NetworkTeam]AddNetworkTeam'
        }
    }
}
