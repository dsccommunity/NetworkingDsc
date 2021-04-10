<#PSScriptInfo
.VERSION 1.0.0
.GUID b215c566-a375-45ff-82e6-8d0b14b58855
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
    Remove a Network Team Interface.
#>
Configuration NetworkTeamInterface_RemoveInterface_Config
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
            Ensure = 'Absent'
            DependsOn = '[NetworkTeam]HostTeam'
        }
    }
}
