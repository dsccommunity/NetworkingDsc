@{
    # Version number of this module.
    moduleVersion = '7.3.0.0'

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
        ReleaseNotes = '- DnsClientGlobalSettings:
  - Fixed SuffixSearchList Empty String Handling - fixes [Issue 398](https://github.com/PowerShell/NetworkingDsc/issues/398).
- NetAdapterAdvancedProperty:
  - Removed validation from RegistryKeyword parameter because the list
    of valid registry keywords is not fixed and will depend on adapter
    driver - fixes [Issue 388](https://github.com/PowerShell/NetworkingDsc/issues/388).
- MSFT_WinsServerAddress
  Added MSFT_WinsServerAddress to control the WINS servers for a given network adapter.
- Test-DscParameterState:
  - This function was enhanced with an optional reversecheck, optional internal
    sorting for arrays.
  - The functions ConvertTo-CimInstance and ConvertTo-Hashtable were added
    required by Test-DscParameterState.
- Fix missing context message content in unit tests - fixes [Issue 405](https://github.com/PowerShell/NetworkingDsc/issues/405).
- Correct style violations in unit tests:
  - Adding `Get`, `Set` and `Test` tags to appropriate `describe` blocks.
  - Removing uneccesary `region` blocks.
  - Conversion of double quotes to single quotes where possible.
  - Replace variables with string litterals in `describe` block description.
- Firewall:
  - Fix bug when LocalAddress or RemoteAddress is specified using CIDR
    notation with number of bits specified in subnet mask (e.g.
    10.0.0.1/8) rather than using CIDR subnet mask notation (e.g
    10.0.0.1/255.0.0.0) - fixes [Issue 404](https://github.com/PowerShell/NetworkingDsc/issues/404).

'

} # End of PSData hashtable
    } # End of PrivateData hashtable
}




