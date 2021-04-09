<#PSScriptInfo
.VERSION 1.0.0
.GUID e1a46ec1-73ff-49e6-849b-81b13917d2b0
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
    Removes the NIC Team 'HostTeam' from the interfaces NIC1, NIC2 and NIC3.
#>
Configuration NetworkTeam_RemoveNetworkTeam_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetworkTeam RemoveNetworkTeam
        {
            Name        = 'HostTeam'
            Ensure      = 'Absent'
            TeamMembers = 'NIC1', 'NIC2', 'NIC3'
        }
    }
}
