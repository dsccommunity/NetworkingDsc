<#PSScriptInfo
.VERSION 1.0.0
.GUID 2ae08974-25ce-4f86-85d0-50394a6ffb46
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/NetworkingDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/NetworkingDsc
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
    Add New Network Team Interface.
#>
Configuration NetworkTeamInterface_AddInterface_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
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
