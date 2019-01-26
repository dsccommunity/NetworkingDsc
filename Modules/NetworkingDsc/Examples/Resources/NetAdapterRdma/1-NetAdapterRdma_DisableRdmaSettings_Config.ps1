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
    This configuration disables RDMA setting on the network adapter.
#>
Configuration NetAdapterRdma_DisableRdmaSettings_Config
{
    Import-DSCResource -ModuleName NetworkingDsc

    Node localhost
    {
        NetAdapterRdma SMBAdapter1
        {
            Name = 'SMB1_1'
            Enabled = $false
        }
    }
}
