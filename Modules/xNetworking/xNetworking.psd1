@{
# Version number of this module.
ModuleVersion = '3.2.0.0'

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

NestedModules = @('Modules\NetworkingDsc.Common\NetworkingDsc.Common.psm1','Modules\NetworkingDsc.ResourceHelper\NetworkingDsc.ResourceHelper.psm1','xNetworkAdapter.psm1')

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
        ReleaseNotes = '- Fixed typo in the example"s Action property from "Blocked" (which isn"t a valid
  value) to "Block"
- Added support for auto generating wiki, help files, markdown linting
  and checking examples.
- Added NetworkingDsc.ResourceHelper module based on copy from [PSDscResources](https://github.com/PowerShell/PSDscResources/blob/dev/DscResources/CommonResourceHelper.psm1).
- MSFT_xFirewall:
  - Cleaned up ParameterList table layout and moved into a new file
    (MSFT_xFirewall.data.psd1).
  - Separated Localization strings into strings file.
  - Added standard help blocks to all functions to meet HQRM standards.
  - Added CmdletBinding attribute to all functions to meet HQRM standards.
  - Style changes to meet HQRM standards.
  - Fixed issue using CIDR notation for LocalAddress or RemoteAddress.
    See [GitHub issue](https://github.com/PowerShell/xNetworking/issues/169).
  - Fixed integration tests so that values being set are correctly tested.
  - Added integration tests for Removal of Firewall rule.
- Added NetworkingDsc.Common module to contain shared networking functions.
- MSFT_xDNSServerAddress:
  - Separated Localization strings into strings file.
- MSFT_xDefaultGatewayAddress:
  - Separated Localization strings into strings file.
  - Style changes to meet HQRM standards.
- MSFT_xDhcpClient:
  - Separated Localization strings into strings file.
  - Fix parameter descriptions in MOF file.
  - Style changes to meet HQRM standards.
- MSFT_xDnsClientGlobalSetting:
  - Renamed Localization strings file to be standard naming format.
  - Moved ParameterList into a new file (MSFT_xDnsClientGlobalSetting.data.psd1).
  - Style changes to meet HQRM standards.
  - Removed New-TerminatingError function because never called.
  - Converted to remove Invoke-Expression.
- MSFT_xDnsConnectionSuffix:
  - Separated Localization strings into strings file.
  - Style changes to meet HQRM standards.
- MSFT_xHostsFile:
  - Renamed Localization strings file to be standard naming format.
  - Style changes to meet HQRM standards.
  - Refactored for performance
    - Code now reads 38k lines in > 1 second vs 4
  - Now ignores inline comments
  - Added more integration tests
- MSFT_xIPAddress:
  - Separated Localization strings into strings file.
  - Style changes to meet HQRM standards.
- MSFT_xNetAdapterBinding:
  - Separated Localization strings into strings file.
  - Style changes to meet HQRM standards.
- MSFT_xNetAdapterRDMA:
  - Renamed Localization strings file to be standard naming format.
  - Style changes to meet HQRM standards.
- MSFT_xNetBIOS:
  - Renamed Localization strings file to be standard naming format.
  - Style changes to meet HQRM standards.
- MSFT_xNetConnectionProfile:
  - Separated Localization strings into strings file.
  - Style changes to meet HQRM standards.
- MSFT_xNetworkTeam:
  - Style changes to meet HQRM standards.
- MSFT_xNetworkTeamInterface:
  - Updated integration tests to remove Invoke-Expression.
  - Style changes to meet HQRM standards.
- MSFT_xRoute:
  - Separated Localization strings into strings file.
  - Style changes to meet HQRM standards.
- MSFT_xFirewall:
  - Converted to remove Invoke-Expression.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}






