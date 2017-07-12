@{
# Version number of this module.
ModuleVersion = '5.0.0.0'

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
        ReleaseNotes = '- Find-NetworkAdapter:
  - Fixed to return null if exception thrown.
  - Allowed passing no selection parameters.
- MSFT_xNetAdapterName:
  - Fixed bug in Get-TargetResource when Name is the only adapter selector parameter.
  - Improved verbose logging.
  - More improvements to verbose logging.
- Added Get-DnsClientServerStaticAddress to NetworkingDsc.Common to return statically
  assigned DNS server addresses to support fix for [issue 113](https://github.com/PowerShell/xNetworking/issues/113).
- MSFT_xDNSserverAddress:
  - Added support for setting DNS Client to DHCP for [issue 113](https://github.com/PowerShell/xNetworking/issues/113).
  - Added new examples to show how to enable DHCP on DNS Client.
  - Improved integration test coverage to enable testing of multiple addresses and
    DHCP.
  - Converted exception creation to use common exception functions.
- MSFT_xDhcpClient:
  - Updated example to also cover setting DNS Client to DHCP.
- Added the VS Code PowerShell extension formatting settings that cause PowerShell
  files to be formatted as per the DSC Resource kit style guidelines.
- MSFT_xDefaultGatewayAddress:
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.
- Updated badges in README.MD to match the layout from PSDscResources.
- MSFT_xIPAddress:
  - BREAKING CHANGE: Adding support for multiple IP addresses being assigned.
 
'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}









