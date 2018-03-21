@{
# Version number of this module.
moduleVersion = '5.6.0.0'

# ID used to uniquely identify this module
GUID = 'e6647cc3-ce9c-4c86-9eb8-2ee8919bf358'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2017 Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Module with DSC Resources for Networking area'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xNetworking/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xNetworking'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '- Reordered resource list in README.MD to be alphabetical and added
  missing resource xNetAdapterAdvancedProperty - Fixes [issue 309](https://github.com/PowerShell/xNetworking/issues/309).
- MSFT_xNetworkTeamInterface:
  - Corrected style and formatting to meet HQRM guidelines.
  - Updated tests to meet Pester v4 guidelines.
  - Converted exceptions to use ResourceHelper functions.
  - Changed unit tests to output Verbose logs.
- MSFT_xNetAdapterAdvancedProperty:
  - Added a number of additional advanced properties.
  - Fixes [issue 314](https://github.com/PowerShell/xNetworking/issues/314).
- MSFT_xNetBIOS:
  - Corrected style and formatting to meet HQRM guidelines.
  - Ensured CommonTestHelper.psm1 is loaded before running unit tests.
- MSFT_xNetworkTeam:
  - Corrected style and formatting to meet HQRM guidelines.
  - Added missing default from MOF description of Ensure parameter.
  - Fixed `Get-TargetResource` to always output Ensure parameter.
  - Changed unit tests to output Verbose logs.
- MSFT_xNetConnectionProfile:
  - Corrected style and formatting to meet HQRM guidelines.
- Updated tests to meet Pester V4 guidelines - Fixes [Issue 272](https://github.com/PowerShell/xNetworking/issues/272).

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}














