<#PSScriptInfo
.VERSION 1.0.0
.GUID aaf5817d-3f61-4c88-881a-f07d660be548
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
    This configuration enables RDMA setting on the network adapter.
#>
Configuration NetAdapterRdma_EnableRdmaSettings_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterRdma EnableRdmaSettings
        {
            Name = 'SMB1_1'
            Enabled = $true
        }
    }
}
