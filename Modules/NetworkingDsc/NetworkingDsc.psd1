@{
    # Version number of this module.
    moduleVersion = '6.0.0.0'

    # ID used to uniquely identify this module
    GUID              = 'e6647cc3-ce9c-4c86-9eb8-2ee8919bf358'

    # Author of this module
    Author            = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName       = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright         = '(c) 2018 Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Module with DSC Resources for Networking area'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion        = '4.0'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport   = '*'

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{

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
        ReleaseNotes = '- New Example 2-ConfigureSuffixSearchList.ps1 for multiple
  SuffixSearchList entries for resource DnsClientGlobalSetting.
- BREAKING CHANGE:
  - Renamed xNetworking to NetworkingDsc - fixes [Issue 119](https://github.com/PowerShell/NetworkingDsc/issues/290).
  - Changed all MSFT\_xResourceName to MSFT\_ResourceName.
  - Updated DSCResources, Examples, Modules and Tests with new naming.
  - Updated Year to 2018 in License and Manifest.
  - Updated README.md from xNetworking to NetworkingDsc.
- MSFT_IPAddress:
  - Updated to allow setting multiple IP Addresses
    when one is already set - Fixes [Issue 323](https://github.com/PowerShell/NetworkingDsc/issues/323)
- Corrected CHANGELOG.MD to report that issue with InterfaceAlias matching
  on Adapter description rather than Adapter Name was released in 5.7.0.0
  rather than 5.6.0.0 - See [Issue 315](https://github.com/PowerShell/xNetworking/issues/315).
- MSFT_WaitForNetworkTeam:
  - Added a new resource to set the wait for a network team to become "Up".
- MSFT_NetworkTeam:
  - Improved detection of environmemt for running network team integration
    tests.
- MSFT_NetworkTeamInterface:
  - Improved detection of environmemt for running network team integration
    tests.
- Added a CODE\_OF\_CONDUCT.md with the same content as in the README.md - fixes
  [Issue 337](https://github.com/PowerShell/NetworkingDsc/issues/337).

'

        } # End of PSData hashtable
    } # End of PrivateData hashtable
}

