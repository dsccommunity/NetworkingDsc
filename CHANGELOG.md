# Versions

## Unreleased

## 7.4.0.0

- Added Comment Based Help for `New-NotImplementedException` common
  function - fixes [Issue #411](https://github.com/PowerShell/NetworkingDsc/issues/411).
- Added common function 'Format-Win32NetworkADapterFilterByNetConnectionID'
  to properly accept wild cards for Win32_NetworkAdapter filters.
- Updated MSFT_Netbios to use 'Format-Win32NetworkADapterFilterByNetConnectionID'
  - fixes [Issue #413](https://github.com/PowerShell/NetworkingDsc/issues/413).
- Corrected minor style and consistency issues in `NetworkingDsc.Common.tests.ps1`
  and `NetworkingDsc.Common.ps1`.
- Changed verbose messages in `Test-DscParameterState` to include
  full type name.
- Fixed bug in `Test-DscParameterState` that causes it to return true when
  both the current array and desired array is empty.
- Fix minor style issues in statement case.

## 7.3.0.0

- DnsClientGlobalSettings:
  - Fixed SuffixSearchList Empty String Handling - fixes [Issue #398](https://github.com/PowerShell/NetworkingDsc/issues/398).
- NetAdapterAdvancedProperty:
  - Removed validation from RegistryKeyword parameter because the list
    of valid registry keywords is not fixed and will depend on adapter
    driver - fixes [Issue #388](https://github.com/PowerShell/NetworkingDsc/issues/388).
- MSFT_WinsServerAddress
  Added MSFT_WinsServerAddress to control the WINS servers for a given network adapter.
- Test-DscParameterState:
  - This function was enhanced with an optional reversecheck, optional internal
    sorting for arrays.
  - The functions ConvertTo-CimInstance and ConvertTo-Hashtable were added
    required by Test-DscParameterState.
- Fix missing context message content in unit tests - fixes [Issue #405](https://github.com/PowerShell/NetworkingDsc/issues/405).
- Correct style violations in unit tests:
  - Adding `Get`, `Set` and `Test` tags to appropriate `describe` blocks.
  - Removing uneccesary `#region` blocks.
  - Conversion of double quotes to single quotes where possible.
  - Replace variables with string litterals in `describe` block description.
- Firewall:
  - Fix bug when LocalAddress or RemoteAddress is specified using CIDR
    notation with number of bits specified in subnet mask (e.g.
    10.0.0.1/8) rather than using CIDR subnet mask notation (e.g
    10.0.0.1/255.0.0.0) - fixes [Issue #404](https://github.com/PowerShell/NetworkingDsc/issues/404).

## 7.2.0.0

- NetAdapterAdvancedProperty:
  - Added support for RegistryKeyword `MaxRxRing1Length` and
    `NumRxBuffersSmall` - fixes [Issue #387](https://github.com/PowerShell/NetworkingDsc/issues/387).
- Firewall:
  - Prevent 'Parameter set cannot be resolved using the specified named
    parameters' error when updating rule when group name is specified - fixes
    [Issue #130](https://github.com/PowerShell/NetworkingDsc/issues/130) and
    [Issue #191](https://github.com/PowerShell/NetworkingDsc/issues/191).
- Opted into Common Tests 'Common Tests - Validate Localization' -
  fixes [Issue #393](https://github.com/PowerShell/NetworkingDsc/issues/393).
- Combined all `NetworkingDsc.ResourceHelper` module functions into
  `NetworkingDsc.Common` module - fixes [Issue #394](https://github.com/PowerShell/NetworkingDsc/issues/394).
- Renamed all localization strings so that they are detected by
  'Common Tests - Validate Localization'.
- Fixed issues with mismatched localization strings.
- Updated all common functions with the latest versions from
  [DSCResource.Template](https://github.com/PowerShell/DSCResource.Template).
- Fixed an issue with the helper function `Test-IsNanoServer` that
  prevented it to work. Though the helper function is not used, so this
  issue was not caught until now when unit tests was added.
- Corrected style violations in `NetworkingDsc.Common`.

## 7.1.0.0

- New Resource: NetAdapterState to enable or disable a network adapter - fixes
  [Issue #365](https://github.com/PowerShell/NetworkingDsc/issues/365)
- Fix example publish to PowerShell Gallery by adding `gallery_api`
  environment variable to `AppVeyor.yml` - fixes [Issue #385](https://github.com/PowerShell/NetworkingDsc/issues/385).
- MSFT_Proxy:
  - Fixed `ProxyServer`, `ProxyServerExceptions` and `AutoConfigURL`
    parameters so that they correctly support strings longer than 255
    characters - fixes [Issue #378](https://github.com/PowerShell/NetworkingDsc/issues/378).

## 7.0.0.0

- Refactored module folder structure to move resource to root folder of
  repository and remove test harness - fixes [Issue #372](https://github.com/PowerShell/NetworkingDsc/issues/372).
- Removed module conflict tests because only required for harness style
  modules.
- Opted into Common Tests 'Validate Example Files To Be Published',
  'Validate Markdown Links' and 'Relative Path Length'.
- Added 'DscResourcesToExport' to manifest to improve information in
  PowerShell Gallery and removed wildcards from 'FunctionsToExport',
  'CmdletsToExport', 'VariablesToExport' and 'AliasesToExport' - fixes
  [Issue #376](https://github.com/PowerShell/NetworkingDsc/issues/376).
- MSFT_NetIPInterface:
  - Added `Dhcp`, `WeakHostReceive` and `WeakHostSend` parameters so that
    MSFT_DHCPClient, MSFT_WeakHostReceive, MSFT_WeakHostSend can be
    deprecated - fixes [Issue #360](https://github.com/PowerShell/NetworkingDsc/issues/360).
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
    exists and 'Ensure' returns 'Present' even when actual TeamMembers do
    not match 'TeamMembers' parameter - fixes [Issue #342](https://github.com/PowerShell/NetworkingDsc/issues/342).
- Updated examples to format required for publishing to PowerShell Gallery - fixes
  [Issue #374](https://github.com/PowerShell/NetworkingDsc/issues/374).
- MSFT_NetAdapterAdvancedProperty:
  - Fixes NetworkAdapterName being returned in Name property when calling
    Get-TargetResourceFixes - fixes [Issue #370](https://github.com/PowerShell/NetworkingDsc/issues/370).

## 6.3.0.0

- MSFT_IPAddress:
  - Updated to allow retaining existing addresses in order to support cluster
    configurations as well.

## 6.2.0.0

- Added .VSCode settings for applying DSC PSSA rules - fixes [Issue #357](https://github.com/PowerShell/NetworkingDsc/issues/357).
- Updated LICENSE file to match the Microsoft Open Source Team standard - fixes
  [Issue #363](https://github.com/PowerShell/NetworkingDsc/issues/363)
- MSFT_NetIPInterface:
  - Added a new resource for configuring the IP interface settings for a network
    interface.

## 6.1.0.0

- MSFT_Firewall:
  - Added full stop to end of MOF field descriptions.
  - Support for `[`, `]` and `*` characters in the Name property
    added - fixes [Issue #348](https://github.com/PowerShell/NetworkingDsc/issues/348).
  - Improved unit tests to meet style guidelines.

## 6.0.0.0

- New Example 2-ConfigureSuffixSearchList.ps1 for multiple
  SuffixSearchList entries for resource DnsClientGlobalSetting.
- BREAKING CHANGE:
  - Renamed xNetworking to NetworkingDsc - fixes [Issue #119](https://github.com/PowerShell/NetworkingDsc/issues/290).
  - Changed all MSFT\_xResourceName to MSFT\_ResourceName.
  - Updated DSCResources, Examples, Modules and Tests with new naming.
  - Updated Year to 2018 in License and Manifest.
  - Updated README.md from xNetworking to NetworkingDsc.
- MSFT_IPAddress:
  - Updated to allow setting multiple IP Addresses
    when one is already set - Fixes [Issue #323](https://github.com/PowerShell/NetworkingDsc/issues/323)
- Corrected CHANGELOG.MD to report that issue with InterfaceAlias matching
  on Adapter description rather than Adapter Name was released in 5.7.0.0
  rather than 5.6.0.0 - See [Issue #315](https://github.com/PowerShell/xNetworking/issues/315).
- MSFT_WaitForNetworkTeam:
  - Added a new resource to set the wait for a network team to become 'Up'.
- MSFT_NetworkTeam:
  - Improved detection of environmemt for running network team integration
    tests.
- MSFT_NetworkTeamInterface:
  - Improved detection of environmemt for running network team integration
    tests.
- Added a CODE\_OF\_CONDUCT.md with the same content as in the README.md - fixes
  [Issue #337](https://github.com/PowerShell/NetworkingDsc/issues/337).

## 5.7.0.0

- Enabled PSSA rule violations to fail build - Fixes [Issue #320](https://github.com/PowerShell/xNetworking/issues/320).
- MSFT_xNetAdapterAdvancedProperty:
  - Enabled setting the same property on multiple network
    adapters - Fixes [issue #324](https://github.com/PowerShell/xNetworking/issues/324).
- MSFT_xNetBIOS:
  - Fix issue with InterfaceAlias matching on Adapter description
    rather than Adapter Name - Fixes [Issue #315](https://github.com/PowerShell/xNetworking/issues/315).

## 5.6.0.0

- Reordered resource list in README.MD to be alphabetical and added
  missing resource xNetAdapterAdvancedProperty - Fixes [issue #309](https://github.com/PowerShell/xNetworking/issues/309).
- MSFT_xNetworkTeamInterface:
  - Corrected style and formatting to meet HQRM guidelines.
  - Updated tests to meet Pester v4 guidelines.
  - Converted exceptions to use ResourceHelper functions.
  - Changed unit tests to output Verbose logs.
- MSFT_xNetAdapterAdvancedProperty:
  - Added a number of additional advanced properties.
  - Fixes [issue #314](https://github.com/PowerShell/xNetworking/issues/314).
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
- Updated tests to meet Pester V4 guidelines - Fixes [Issue #272](https://github.com/PowerShell/xNetworking/issues/272).

## 5.5.0.0

- MSFT_xNetAdapterAdvancedProperty:
  - Created new resource configuring AdvancedProperties for NetAdapter
- MSFT_xNetAdapterLso:
  - Corrected style and formatting to meet HQRM guidelines.
  - Updated tests to meet Pester v4 guidelines.
- MSFT_xNetAdapterName:
  - Corrected style and formatting to meet HQRM guidelines.
  - Updated tests to meet Pester v4 guidelines.
- MSFT_xNetAdapterRDMA:
  - Corrected style and formatting to meet HQRM guidelines.
  - Updated tests to meet Pester v4 guidelines.
  - Converted exceptions to use ResourceHelper functions.
  - Improved integration tests to preserve system status and run in more
    scenarios.
- MSFT_xNetBIOS:
  - Corrected style and formatting to meet HQRM guidelines.
  - Updated tests to meet Pester v4 guidelines.
  - Converted exceptions to use ResourceHelper functions.
  - Improved integration tests to preserve system status, run in more
    scenarios and more effectively test the resource.
  - Changed to report back error if unable to set NetBIOS setting.
- MSFT_xWinsSetting:
  - Created new resource for enabling/disabling LMHOSTS lookup and
    enabling/disabling WINS name resoluton using DNS.
- MSFT_xNetworkTeam:
  - Corrected style and formatting to meet HQRM guidelines.
  - Updated tests to meet Pester v4 guidelines.
  - Converted exceptions to use ResourceHelper functions.

## 5.4.0.0

- MSFT_xIPAddressOption:
  - Added a new resource to set the SkipAsSource option for an IP address.
- MSFT_xWeakHostSend:
  - Created the new Weak Host Send resource.
- MSFT_xWeakHostReceive:
  - Created the new Weak Host Receive resource.
- MSFT_xRoute:
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.
  - Changed unit tests so that they can be run in any order.
  - Included default values in MOF file so that they are displayed
    in Wiki documentation.
  - Converted tests to meet Pester V4 standards.

## 5.3.0.0

- MSFT_xProxySettings:
  - Created new resource configuring proxy settings.
- MSFT_xDefaultGatewayAddress:
  - Correct `2-SetDefaultGateway.md` address family and improve example
    description - fixes [Issue #275](https://github.com/PowerShell/xNetworking/issues/275).
- MSFT_xIPAddress:
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.
  - Changed unit tests so that they can be run in any order.
- MSFT_xNetAdapterBinding:
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.

## 5.2.0.0

- Added `Documentation and Examples` section to Readme.md file - see
  [issue #259](https://github.com/PowerShell/xNetworking/issues/259).
- Prevent unit tests from DSCResource.Tests from running during test
  execution - fixes [Issue #264](https://github.com/PowerShell/xNetworking/issues/264).
- MSFT_xNetworkTeamInterface:
  - Updated Test-TargetResource to substitute VLANID value 0 to $null
- MSFT_xNetAdapterRsc:
  - Created new resource configuring Rsc
- MSFT_xNetAdapterRss:
  - Created new resource configuring Rss
- MSFT_xHostsFile:
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.

## 5.1.0.0

- MSFT_xDhcpClient:
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
    [issue #237](https://github.com/PowerShell/xNetworking/issues/237).
  - Corrected style and formatting to meet HQRM guidelines.
- MSFT_xIPAddress:
  - Improved examples to clarify how to set IP Address prefix -
    see [issue #239](https://github.com/PowerShell/xNetworking/issues/239).
- MSFT_xFirewall:
  - Fixed bug with DisplayName not being set correctly in some
    situations - see [issue #234](https://github.com/PowerShell/xNetworking/issues/234).
  - Corrected style and formatting to meet HQRM guidelines.
  - Converted exceptions to use ResourceHelper functions.
- Added .github support files:
  - CONTRIBUTING.md
  - ISSUE_TEMPLATE.md
  - PULL_REQUEST_TEMPLATE.md
- Opted into Common Tests 'Validate Module Files' and 'Validate Script Files'.
- Converted files with UTF8 with BOM over to UTF8 - fixes [Issue 250](https://github.com/PowerShell/xNetworking/issues/250).
- MSFT_xFirewallProfile:
  - Created new resource configuring firewall profiles.
- MSFT_xNetConnectionProfile:
  - Corrected style and formatting to meet HQRM guidelines.
  - Added validation for provided parameters.
  - Prevent testing parameter values of connection that aren't set in resource -
    fixes [Issue 254](https://github.com/PowerShell/xNetworking/issues/254).
  - Improved unit test coverage for this resource.

## 5.0.0.0

- Find-NetworkAdapter:
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

## 4.1.0.0

- Added integration test to test for conflicts with other common resource kit modules.
- Prevented ResourceHelper and Common module cmdlets from being exported to resolve
  conflicts with other resource modules.

## 4.0.0.0

- Converted to use AppVeyor.psm1 in DSCResource.Tests repository.
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

## 3.2.0.0

- Fixed typo in the example's Action property from "Blocked" (which isn't a valid
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

## 3.1.0.0

- Changed parameter format in Readme.md to improve information coverage and consistency.
- Changed all MOF files to be consistent and meet HQRM guidelines.
- Removed most markdown errors (MD*) in Readme.md.
- Added xNetAdapterRDMA resource
- Fixes to support changes to DSCResource.Tests.

## 3.0.0.0

- Corrected integration test filenames:
  - MSFT_xDefaultGatewayAddress.Integration.Tests.ps1
  - MSFT_xDhcpClient.Integration.Tests.ps1
  - MSFT_xDNSConnectionSuffix.Integration.Tests.ps1
  - MSFT_xNetAdapterBinding.Integration.Tests.ps1
- Updated all integration tests to use v1.1.0 header and script variable context.
- Updated all unit tests to use v1.1.0 header and script variable context.
- Removed uneccessary global variable from MSFT_xNetworkTeam.integration.tests.ps1
- Converted Invoke-Expression in all integration tests to &.
- Fixed unit test description in xNetworkAdapter.Tests.ps1
- xNetAdapterBinding
  - Added support for the use of wildcard (*) in InterfaceAlias parameter.
- BREAKING CHANGE - MSFT_xIPAddress: SubnetMask parameter renamed to PrefixLength.

## 2.12.0.0

- Fixed bug in MSFT_xIPAddress resource when xIPAddress follows xVMSwitch.
- Added the following resources:
  - MSFT_xNetworkTeamInterface resource to add/remove network team interfaces
- Added conditional loading of LocalizedData to MSFT_xHostsFile and
  MSFT_xNetworkTeam to prevent failures while loading those resources on systems
  with $PSUICulture other than en-US

## 2.11.0.0

- Added the following resources:
  - MSFT_xDnsClientGlobalSetting resource to configure the DNS Suffix Search List
    and Devolution.
- Converted AppVeyor.yml to pull Pester from PSGallery instead of Chocolatey.
- Changed AppVeyor.yml to use default image.
- Fix xNetBios unit tests to work on default appveyor image.
- Fix bug in xRoute when removing an existing route.
- Updated xRoute integration tests to use v1.1.0 test header.
- Extended xRoute integration tests to perform both add and remove route tests.

## 2.10.0.0

- Added the following resources:
  - MSFT_xNetAdapterBinding resource to enable/disable network adapter bindings.
- Fixed bug where xHostsFile would duplicate an entry instead of updating an
  existing one
- Updated Sample_xIPAddress_*.ps1 examples to show correct usage of setting a
  Static IP address to prevent issue when DHCP assigned IP address already
  matches staticly assigned IP address.

## 2.9.0.0

- MSFT_xDefaultGatewayAddress: Added Integration Tests.
- MSFT_xDhcpClient: Added Integration Tests.
- MSFT_xDnsConnectionSuffix: Added Integration Tests.
- MSFT_xDnsServerAddress: Added Integration Tests.
- MSFT_xIPAddress: Added Integration Tests.
- MSFT_xDhcpClient: Fixed logged message in Test-TargetResource.
- Added functions:
  - Get-xNetworkAdapterName
  - Test-xNetworkAdapterName
  - Set-xNetworkAdapterName

## 2.8.0.0

- Templates folder removed. Use the test templates in them
  [Tests.Template folder in the DSCResources repository](https://github.com/PowerShell/DscResources/tree/master/Tests.Template)
  instead.
- Added the following resources:
  - MSFT_xHostsFile resource to manage hosts file entries.
- MSFT_xFirewall: Fix test of Profile parameter status.
- MSFT_xIPAddress: Fix false negative when desired IP is a substring of current IP.

## 2.7.0.0

- Added the following resources:
  - MSFT_xNetworkTeam resource to manage native network adapter teaming.

## 2.6.0.0

- Added the following resources:
  - MSFT_xDhcpClient resource to enable/disable DHCP on individual interfaces.
  - MSFT_xRoute resource to manage network routes.
  - MSFT_xNetBIOS resource to configure NetBIOS over TCP/IP settings on
    individual interfaces.
- MSFT_*: Unit and Integration tests updated to use
    DSCResource.Tests\TestHelper.psm1 functions.
- MSFT_*: Resource Name added to all unit test Desribes.
- Templates update to use DSCResource.Tests\TestHelper.psm1 functions.
- MSFT_xNetConnectionProfile: Integration tests fixed when more than one
  connection profile present.
- Changed AppVeyor.yml to use WMF 5 build environment.
- MSFT_xIPAddress: Removed test for DHCP Status.
- MSFT_xFirewall: New parameters added:
  - DynamicTransport
  - EdgeTraversalPolicy
  - LocalOnlyMapping
  - LooseSourceMapping
  - OverrideBlockRules
  - Owner
- All unit & integration tests updated to be able to be run from any folder under
  tests directory.
- Unit & Integration test template headers updated to match DSCResource templates.

## 2.5.0.0

- Added the following resources:
  - MSFT_xDNSConnectionSuffix resource to manage connection-specific DNS suffixes.
  - MSFT_xNetConnectionProfile resource to manage Connection Profiles for interfaces.
- MSFT_xDNSServerAddress: Corrected Verbose logging messages when multiple DNS
  adddressed specified.
- MSFT_xDNSServerAddress: Change to ensure resource terminates if DNS Server
  validation fails.
- MSFT_xDNSServerAddress: Added Validate parameter to enable DNS server validation
  when changing server addresses.
- MSFT_xFirewall: ApplicationPath Parameter renamed to Program for consistency
  with Cmdlets.
- MSFT_xFirewall: Fix to prevent error when DisplayName parameter is set on an
  existing rule.
- MSFT_xFirewall: Setting a different DisplayName parameter on an existing rule
  now correctly reports as needs change.
- MSFT_xFirewall: Changed DisplayGroup parameter to Group for consistency with
  Cmdlets and reduce confusion.
- MSFT_xFirewall: Changing the Group of an existing Firewall rule will recreate
  the Firewall rule rather than change it.
- MSFT_xFirewall: New parameters added:
  - Authentication
  - Encryption
  - InterfaceAlias
  - InterfaceType
  - LocalAddress
  - LocalUser
  - Package
  - Platform
  - RemoteAddress
  - RemoteMachine
  - RemoteUser
- MSFT_xFirewall: Profile parameter now handled as an Array.

## 2.4.0.0

- Added following resources:
  - MSFT_xDefaultGatewayAddress
- MSFT_xFirewall: Removed code using DisplayGroup to lookup Firewall Rule because
  it was redundant.
- MSFT_xFirewall: Set-TargetResource now updates firewall rules instead of
  recreating them.
- MSFT_xFirewall: Added message localization support.
- MSFT_xFirewall: Removed unnecessary code for handling multiple rules with same
  name.
- MSFT_xDefaultGatewayAddress: Removed unnecessary try/catch logic from around
  networking cmdlets.
- MSFT_xIPAddress: Removed unnecessary try/catch logic from around networking cmdlets.
- MSFT_xDNSServerAddress: Removed unnecessary try/catch logic from around
  networking cmdlets.
- MSFT_xDefaultGatewayAddress: Refactored to add more unit tests and cleanup logic.
- MSFT_xIPAddress: Network Connection Profile no longer forced to Private when
  IP address changed.
- MSFT_xIPAddress: Refactored to add more unit tests and cleanup logic.
- MSFT_xDNSServerAddress: Refactored to add more unit tests and cleanup logic.
- MSFT_xFirewall: Refactored to add more unit tests and cleanup logic.
- MSFT_xIPAddress: Removed default gateway parameter - use xDefaultGatewayAddress
  resource.
- MSFT_xIPAddress: Added check for IP address format not matching address family.
- MSFT_xDNSServerAddress: Corrected error message when address format doesn't
  match address family.

## 2.3.0.0

- MSFT_xDNSServerAddress: Added support for setting DNS for both IPv4 and IPv6
  on the same Interface
- MSFT_xDNSServerAddress: AddressFamily parameter has been changed to mandatory.
- Removed xDscResourceDesigner tests (moved to common tests)
- Fixed Test-TargetResource to test against all provided parameters
- Modified tests to not copy file to Program Files

- Changes to xFirewall causes Get-DSCConfiguration to no longer crash
  - Modified Schema to reduce needed functions.
  - General re-factoring and clean up of xFirewall.
  - Added Unit and Integration tests to resource.

## 2.2.0.0

- Changes in xFirewall resources to meet Test-xDscResource criteria

## 2.1.1.1

- Updated to fix issue with Get-DscConfiguration and xFirewall

## 2.1.0

- Added validity check that IPAddress and IPAddressFamily conforms with each other

## 2.0.0.0

- Adding the xFirewall resource

## 1.0.0.0

- Initial release with the following resources:
  - xIPAddress
  - xDnsServerAddress
