@{
    # Version number of this module.
    moduleVersion = '7.4.0.0'

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
        'NetAdapterState',
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
        ReleaseNotes = '- Added Comment Based Help for `New-NotImplementedException` common
  function - fixes [Issue 411](https://github.com/PowerShell/NetworkingDsc/issues/411).
- Added common function "Format-Win32NetworkADapterFilterByNetConnectionID"
  to properly accept wild cards for Win32_NetworkAdapter filters.
- Updated MSFT_Netbios to use "Format-Win32NetworkADapterFilterByNetConnectionID"
  - fixes [Issue 413](https://github.com/PowerShell/NetworkingDsc/issues/413).
- Corrected minor style and consistency issues in `NetworkingDsc.Common.tests.ps1`
  and `NetworkingDsc.Common.ps1`.
- Changed verbose messages in `Test-DscParameterState` to include
  full type name.
- Fixed bug in `Test-DscParameterState` that causes it to return true when
  both the current array and desired array is empty.
- Fix minor style issues in statement case.

'

} # End of PSData hashtable
    } # End of PrivateData hashtable
}





