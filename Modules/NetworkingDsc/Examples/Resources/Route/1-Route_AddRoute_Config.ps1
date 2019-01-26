<#PSScriptInfo
.VERSION 1.0.0
.GUID ef978ef1-a0d2-4266-a78d-56b232a42d1d
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
    Add a net route to the Ethernet interface.
#>
Configuration Route_AddRoute_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        Route NetRoute1
        {
            Ensure = 'Present'
            InterfaceAlias = 'Ethernet'
            AddressFamily = 'IPv4'
            DestinationPrefix = '192.168.0.0/16'
            NextHop = '192.168.120.0'
            RouteMetric = 200
        }
    }
}
