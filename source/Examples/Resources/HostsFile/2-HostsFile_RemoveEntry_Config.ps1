<#PSScriptInfo
.VERSION 1.0.0
.GUID ac021c17-02e7-4189-b40b-d7448ab73e99
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
    Remove a host from the hosts file.
#>
Configuration HostsFile_RemoveEntry_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        HostsFile HostsFileRemoveEntry
        {
            HostName  = 'Host01'
            IPAddress = '192.168.0.1'
            Ensure    = 'Absent'
        }
    }
}
