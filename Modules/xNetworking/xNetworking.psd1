@{
# Version number of this module.
ModuleVersion = '5.1.0.0'

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
        ReleaseNotes = '- MSFT_xDhcpClient:
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.
- README.MD:
  - Cleaned up badges by putting them into a table.
- MSFT_xDnsConnectionSuffix:
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.
- README.MD:
  - Converted badges to use branch header as used in xSQLServer.
- Added standard .markdownlint.json to configure rules to run on
  Markdown files.
- MSFT_xDnsClientGlobalSetting:
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.
- Updated year to 2017 in LICENSE and module manifest.
- MSFT_xDnsServerAddress:
  - Fix error when setting address on adapter where NameServer
    Property does not exist in registry for interface - see
    [issue 237](https://github.com/PowerShell/xNetworking/issues/237).
  - Corrected style and formatting to meet HQRM guidelines.
- MSFT_xIPAddress:
  - Improved examples to clarify how to set IP Address prefix -
    see [issue 239](https://github.com/PowerShell/xNetworking/issues/239).
- MSFT_xFirewall:
  - Fixed bug with DisplayName not being set correctly in some
    situations - see [issue 234](https://github.com/PowerShell/xNetworking/issues/234).
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.
- Added .github support files:
  - CONTRIBUTING.md
  - ISSUE_TEMPLATE.md
  - PULL_REQUEST_TEMPLATE.md
- Opted into Common Tests "Validate Module Files" and "Validate Script Files".
- Converted files with UTF8 with BOM over to UTF8 - fixes [Issue 250](https://github.com/PowerShell/xNetworking/issues/250).
- MSFT_xFirewallProfile:
  - Created new resource configuring firewall profiles.
- MSFT_xNetConnectionProfile:
  - Corrected style and formatting to meet HQRM guidelines.
  - Added validation for provided parameters.
  - Prevent testing parameter values of connection that aren"t set in resource -
    fixes [Issue 254](https://github.com/PowerShell/xNetworking/issues/254).
  - Improved unit test coverage for this resource.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}










