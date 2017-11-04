@{
# Version number of this module.
ModuleVersion = '5.2.0.0'

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
        ReleaseNotes = '- Added `Documentation and Examples` section to Readme.md file - see
  [issue 259](https://github.com/PowerShell/xNetworking/issues/259).
- Prevent unit tests from DSCResource.Tests from running during test
  execution - fixes [Issue 264](https://github.com/PowerShell/xNetworking/issues/264).
- MSFT_xNetworkTeamInterface:
  - Updated Test-TargetResource to substitute VLANID value 0 to $null
- MSFT_xNetAdapterRsc:
  - Created new resource configuring Rsc
- MSFT_xNetAdapterRss:
  - Created new resource configuring Rss
- MSFT_xHostsFile:
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}










