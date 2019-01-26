<#PSScriptInfo
.VERSION 1.0.0
.GUID 35f4563f-fae5-4028-b8eb-06939caf62fe
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
    This example enables the following settings on the IPv4 network interface with alias
    'Ethernet':
    - AdvertiseDefaultRoute
    - Avertising
    - AutomaticMetric
    - DirectedMacWolPattern
    - ForceArpNdWolPattern
    - Forwarding
    - IgnoreDefaultRoute
    - ManagedAddressConfiguration
    - NeighborUnreachabilityDetection
    - OtherStatefulConfiguration
    - RouterDiscovery
    The EcnMarking parameter will be set to AppDecide.
#>
Configuration NetIPInterface_MultipleSettings_Config
{
    Import-DscResource -Module NetworkingDsc

    Node localhost
    {
        NetIPInterface MultipleSettings
        {
            InterfaceAlias                  = 'Ethernet'
            AddressFamily                   = 'IPv4'
            AdvertiseDefaultRoute           = 'Enabled'
            Advertising                     = 'Enabled'
            AutomaticMetric                 = 'Enabled'
            DirectedMacWolPattern           = 'Enabled'
            EcnMarking                      = 'AppDecide'
            ForceArpNdWolPattern            = 'Enabled'
            Forwarding                      = 'Enabled'
            IgnoreDefaultRoutes             = 'Enabled'
            ManagedAddressConfiguration     = 'Enabled'
            NeighborUnreachabilityDetection = 'Enabled'
            OtherStatefulConfiguration      = 'Enabled'
            RouterDiscovery                 = 'Enabled'
        }
    }
}
