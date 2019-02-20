@{
    # Version number of this module.
    moduleVersion = '7.0.0.0'

    # ID used to uniquely identify this module
    GUID                 = 'e6647cc3-ce9c-4c86-9eb8-2ee8919bf358'

    # Author of this module
    Author               = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName          = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright            = '(c) 2018 Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Module with DSC Resources for Networking area'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion           = '4.0'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'DefaultGatewayAddress',
        'DnsClientGlobalSetting',
        'DnsConnectionSuffix',
        'DNSServerAddress',
        'Firewall',
        'FirewallProfile',
        'HostsFile',
        'IPAddress',
        'IPAddressOption',
        'NetAdapterAdvancedProperty',
        'NetAdapterBinding',
        'NetAdapterLso',
        'NetAdapterName',
        'NetAdapterRDMA',
        'NetAdapterRsc',
        'NetAdapterRss',
        'NetBIOS',
        'NetConnectionProfile',
        'NetIPInterface',
        'NetworkTeam',
        'NetworkTeamInterface',
        'ProxySettings',
        'Route',
        'WINSSetting'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/PowerShell/NetworkingDsc/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/PowerShell/NetworkingDsc'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
        ReleaseNotes = '- Refactored module folder structure to move resource to root folder of
  repository and remove test harness - fixes [Issue 372](https://github.com/PowerShell/NetworkingDsc/issues/372).
- Removed module conflict tests because only required for harness style
  modules.
- Opted into Common Tests "Validate Example Files To Be Published",
  "Validate Markdown Links" and "Relative Path Length".
- Added "DscResourcesToExport" to manifest to improve information in
  PowerShell Gallery and removed wildcards from "FunctionsToExport",
  "CmdletsToExport", "VariablesToExport" and "AliasesToExport" - fixes
  [Issue 376](https://github.com/PowerShell/NetworkingDsc/issues/376).
- MSFT_NetIPInterface:
  - Added `Dhcp`, `WeakHostReceive` and `WeakHostSend` parameters so that
    MSFT_DHCPClient, MSFT_WeakHostReceive, MSFT_WeakHostSend can be
    deprecated - fixes [Issue 360](https://github.com/PowerShell/NetworkingDsc/issues/360).
- MSFT_DhcpClient:
  - BREAKING CHANGE: Resource has been deprecated and replaced by `Dhcp`
    parameter in MSFT_NetIPInterface.
- MSFT_WeakHostReceive:
  - BREAKING CHANGE: Resource has been deprecated and replaced by `WeakHostReceive`
    parameter in MSFT_NetIPInterface.
- MSFT_WeakHostSend:
  - BREAKING CHANGE: Resource has been deprecated and replaced by `WeakHostSend`
    parameter in MSFT_NetIPInterface.
- MSFT_IPAddress:
  - Updated examples to use NetIPInterface.
- MSFT_NetAdapterName:
  - Updated examples to use NetIPInterface.
- MSFT_DnsServerAddress:
  - Updated examples to use NetIPInterface.
- MSFT_NetworkTeam:
  - Change `Get-TargetResource` to return actual TeamMembers if network team
    exists and "Ensure" returns "Present" even when actual TeamMembers do
    not match "TeamMembers" parameter - fixes [Issue 342](https://github.com/PowerShell/NetworkingDsc/issues/342).
- Updated examples to format required for publishing to PowerShell Gallery - fixes
  [Issue 374](https://github.com/PowerShell/NetworkingDsc/issues/374).
- MSFT_NetAdapterAdvancedProperty:
- Fixes NetworkAdapterName being returned in Name property when calling
  Get-TargetResourceFixes - fixes [Issue 370](https://github.com/PowerShell/NetworkingDsc/issues/370).
'

} # End of PSData hashtable
    } # End of PrivateData hashtable
}

