@{
# Version number of this module.
ModuleVersion = '4.0.0.0'

# ID used to uniquely identify this module
GUID = 'e6647cc3-ce9c-4c86-9eb8-2ee8919bf358'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '(c) 2013 Microsoft Corporation. All rights reserved.'

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
        ReleaseNotes = '- Converted to use AppVeyor.psm1 in DSCResource.Tests repository.
- Converted to use Example and Markdown tests in DSCResource.Tests repository.
- Added CodeCov.io support.
- Added a new example to xDNSServerAddress to clarify setting multiple DNS Servers.
- Fix examples to correct display in auto documentation generation.
- BREAKING CHANGE: Migrated xNetworkAdapter module functionality to xNetAdapterName
  resource.
- Added CommonTestHelper module for aiding testing.
- MSFT_xNetAdapterName:
  - Created new resource for renaming network adapters.
  - Added Find-NetAdapter cmdlet to NetworkingDsc.Common.
- Correct example parameters format to meet style guidelines.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}







