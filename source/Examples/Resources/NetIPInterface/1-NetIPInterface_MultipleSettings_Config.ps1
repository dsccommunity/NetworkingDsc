<#PSScriptInfo
.VERSION 1.0.0
.GUID 35f4563f-fae5-4028-b8eb-06939caf62fe
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
    - NlMtu
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
            NlMtu                           = 1576
        }
    }
}
