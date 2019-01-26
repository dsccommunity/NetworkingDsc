<#PSScriptInfo
.VERSION 1.0.0
.GUID
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
    Removes the NIC Team 'HostTeam' from the interfaces NIC1, NIC2 and NIC3.
#>
Configuration NetworkTeam_RemoveTeam_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetworkTeam HostTeam
        {
            Name        = 'HostTeam'
            Ensure      = 'Absent'
            TeamMembers = 'NIC1', 'NIC2', 'NIC3'
        }
    }
}
