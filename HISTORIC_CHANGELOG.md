# Historic change log for xPSDesiredStateConfiguration

The release notes in the PowerShell Module manifest cannot exceed 10000
characters. Due to a bug in the CI deploy pipeline this is not handled.
This file is to temporary move the older change log history to keep the
change log short.

## [8.10.0.0] - 2019-09-19

### Changed

- Changes to xPSDesiredStateConfiguration
  - Fix keywords to lower-case to align with guideline.
- Added SMB PullServer support for publishing.

## [8.9.0.0] - 2019-08-08

### Changed

- MSFT_xRemoteFile:
  - Add a retry mechanism when the download fails.
- Fixes #631, typo in SQL connection string property name

## [8.8.0.0] - 2019-06-26

### Changed

- Ports fix for the following issue:
  [Issue #142](https://github.com/PowerShell/PSDscResources/issues/142)
  Fixes issue where MsiPackage Integration tests fail if the test HttpListener
  fails to start. Moves the test HttpListener objects to dynamically assigned,
  higher numbered ports to avoid conflicts with other services, and also checks
  to ensure that the ports are available before using them. Adds checks to
  ensure that no outstanding HTTP server jobs are running before attempting to
  setup a new one. Also adds additional instrumentation to make it easier to
  troubleshoot issues with the test HttpListener objects in the future.

## [8.7.0.0] - 2019-05-15

### Changed

- MSFT_xWindowsProcess:
  - Fixes issue where a process will fail to be created if a $Path is passed
    that contains one or more spaces, and the resource is using $Credentials.
  - Fixes issue where a process will fail to be created if $Arguments are
    passed that contain one or more spaces (with or without credentials).
  - Fixes issue where Integration tests fail if empty Arguments are passed.
    [issue #605](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/605)
  - Heavily refactors MSFT_xWindowsProcess.Integration.Tests.ps1 and adds more
    Path and Arguments related test cases.
  - Removes reliance on test file WindowsProcessTestProcess.
- Fixes test failures in xWindowsOptionalFeatureSet.Integration.Tests.ps1 due
  to accessing the windowsOptionalFeatureName variable before it is assigned.
  [issue #612](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/612)
- MSFT_xDSCWebService
  - Fixes [issue
    #536](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/536)
    and starts the deprecation process for configuring a windows firewall
    (exception) rule using xDSCWebService
  - Fixes [issue
    #463](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/463)
    and fixes some bugs introduced with the new firewall rule handling

## [8.6.0.0] - 2019-04-03

### Changed

- Fixes style inconsistencies in PublishModulesAndMofsToPullServer.psm1.
  [issue #530](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/530)
- Suppresses forced Verbose output in MSFT_xArchive.EndToEnd.Tests.ps1,
  MSFT_xDSCWebService.Integration.tests.ps1,
  MSFT_xPackageResource.Integration.Tests.ps1, MSFT_xRemoteFile.Tests.ps1,
  MSFT_xUserResource.Integration.Tests.ps1,
  MSFT_xWindowsProcess.Integration.Tests.ps1, and
  xFileUpload.Integration.Tests.ps1.
  [issue #514](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/514)
- Fixes issue in xGroupResource Integration tests where the tests would fail
  if the System.DirectoryServices.AccountManagement namespace was not loaded.
- Tests\Integration\MSFT_xDSCWebService.Integration.tests.ps1:
  - Fixes issue where tests fail if a self signed certificate for DSC does not
    already exist.
    [issue #581](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/581)
- Fixes all instances of the following PSScriptAnalyzer issues:
  - PSUseOutputTypeCorrectly
  - PSAvoidUsingConvertToSecureStringWithPlainText
  - PSPossibleIncorrectComparisonWithNull
  - PSAvoidDefaultValueForMandatoryParameter
  - PSAvoidUsingInvokeExpression
  - PSUseDeclaredVarsMoreThanAssignments
  - PSAvoidGlobalVars
- xPackage and xMsiPackage
  - Add an ability to ignore a pending reboot if requested by package installation.
- xRemoteFile
  - Updated MatchSource description in README.md.
    [issue #409](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/409)
  - Improved layout of MOF file to move description left.
  - Added function help for all functions.
  - Moved `New-InvalidDataException` to CommonResourceHelper.psm1.
    [issue #544](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/544)
- Added full stops to the end of all functions help in CommonResourceHelper.psm1.
- Added unit tests for `New-InvalidArgumentException`,
  `New-InvalidDataException` and `New-InvalidOperationException`
  CommonResourceHelper.psm1 functions.
- Changes to `MSFT_xDSCWebService`
  - Fixed
    [issue #528](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/528)
    : Unable to disable selfsigned certificates using AcceptSelfSignedCertificates=$false
  - Fixed
    [issue #460](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/460)
    : Redeploy DSC Pull Server fails with error
- Opt-in to the following Meta tests:
  - Common Tests - Custom Script Analyzer Rules
  - Common Tests - Flagged Script Analyzer Rules
  - Common Tests - New Error-Level Script Analyzer Rules
  - Common Tests - Relative Path Length
  - Common Tests - Required Script Analyzer Rules
  - Common Tests - Validate Markdown Links
- Add .markdownlint.json file using settings from
  [here](https://raw.githubusercontent.com/PowerShell/SqlServerDsc/dev/.markdownlint.json)
  as a starting point.
- Changes to `Tests\Unit\MSFT_xMsiPackage.Tests.ps1`
  - Fixes issue where tests fail if executed from a drive other than C:.
    [issue #573](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/573)
- Changes to
  `Tests\Integration\xWindowsOptionalFeatureSet.Integration.Tests.ps1`
  - Fixes issue where tests fail if a Windows Optional Feature that is expected
    to be disabled has a feature state of 'DisabledWithPayloadRemoved'.
    [issue #586](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/586)
- Changes to
  `Tests\Unit\MSFT_xPackageResource.Tests.ps1`
  - Fixes issue where tests fail if run from a folder that contains spaces.
    [issue #580](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/580)
- Changes to test helper Enter-DscResourceTestEnvironment so that it only
  updates DSCResource.Tests when it is longer than 60 minutes since
  it was last pulled. This is to improve performance of test execution
  and reduce the likelihood of connectivity issues caused by inability to
  pull DSCResource.Tests.
  [issue #505](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/505)
- Updated `CommonTestHelper.psm1` to resolve style guideline violations.
- Adds helper functions for use when creating test administrator user accounts,
  and updates the following tests to use credentials created with these
  functions:
  - MSFT_xScriptResource.Integration.Tests.ps1
  - MSFT_xServiceResource.Integration.Tests.ps1
  - MSFT_xWindowsProcess.Integration.Tests.ps1
  - xServiceSet.Integration.Tests.ps1
- Fixes the following issues:
  - [issue #582](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/582)
  - [issue #583](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/583)
  - [issue #584](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/584)
  - [issue #585](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/585)

## [8.5.0.0] - 2019-02-21

### Changed

- Pull server module publishing
  - Removed forced verbose logging from CreateZipFromSource,
    Publish-DSCModulesAndMof and Publish-MOFToPullServer as it polluted the
    console.
- Corrected GitHub Pull Request template to remove referral to
  `BestPractices.MD` which has been combined into `StyleGuidelines.md`
  ([issue #520](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/520)).
- xWindowsOptionalFeature
  - Suppress useless verbose output from `Import-Module` cmdlet.
    ([issue #453](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/453)).
- Changes to xRemoteFile
  - Corrected a resource name in the example xRemoteFile_DownloadFileConfig.ps1
- Fix `MSFT_xDSCWebService` to find
 `Microsoft.Powershell.DesiredStateConfiguration.Service.Resources.dll`
  when server is configured with pt-BR Locales
  ([issue #284](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/284)).
- Changes to xDSCWebService
  - Fixed an issue which prevented the removal of the IIS Application Pool
    created during deployment of an DSC Pull Server instance.
    ([issue #464](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/464))
  - Fixed an issue where a Pull Server cannot be deployed on a machine when IIS
    Express is installed aside a full blown IIS
    ([issue #191](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/191))
- Update `CommonResourceHelper` unit tests to meet Pester 4.0.0
  standards
  ([issue #473](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/473)).
- Update `ResourceHelper` unit tests to meet Pester 4.0.0
  standards
  ([issue #473](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/473)).
- Update `MSFT_xDSCWebService` unit tests to meet Pester 4.0.0
  standards
  ([issue #473](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/473)).
- Update `MSFT_xDSCWebService` integration tests to meet Pester 4.0.0
  standards
  ([issue #473](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/473)).
- Refactored `MSFT_xDSCWebService` integration tests to meet current
  standards and to use Pester TestDrive.
- xArchive
  - Fix end-to-end tests
    ([issue #457](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/457)).
  - Update integration tests to meet Pester 4.0.0 standards.
  - Update end-to-end tests to meet Pester 4.0.0 standards.
  - Update unit and integration tests to meet Pester 4.0.0 standards.
  - Wrapped all path and identifier strings in verbose messages with
    quotes to make it easier to identify the limit of the string when
    debugging.
  - Refactored date/time checksum code to improve testability and ensure
    tests can run on machines with localized datetime formats that are not
    US.
  - Fix 'Get-ArchiveEntryLastWriteTime' to return `[datetime]`
    ([issue #471](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/471)).
  - Improved verbose logging to make debugging path issues easier.
  - Added handling for '/' as a path seperator by backporting code from
    PSDscResources -
    ([issue #469](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/469)).
  - Copied unit tests from
    [PSDscResources](https://github.com/PowerShell/PSDscResources).
  - Added .gitattributes file and removed git configuration from AppVeyor
    to ensure CRLF settings are configured correctly for the repository.
- Updated '.vscode\settings.json' to refer to AnalyzerSettings.psd1 so that
  custom syntax problems are highlighted in Visual Studio Code.
- Fixed style guideline violations in `CommonResourceHelper.psm1`.
- Changes to xService
  - Fixes issue where Get-TargetResource or Test-TargetResource will throw an
    exception if the target service is configured with a non-existent
    dependency.
  - Refactored Get-TargetResource Unit tests.
- Changes to xPackage
  - Fixes an issue where incorrect verbose output was displayed if product
    found.
    ([issue #446](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/446))
- Fixes files which are getting triggered for re-encoding after recent pull
  request (possibly #472).
- Moves version and change history from README.MD to new file, CHANGELOG.MD.
- Fixes markdown issues in README.MD and HighQualityResourceModulePlan.md.
- Opted in to 'Common Tests - Validate Markdown Files'
- Changes to xPSDesiredStateConfiguration
  - In AppVeyor CI the tests are split into three separate jobs, and also
    run tests on two different build worker images (Windows Server 2012R2
    and Windows Server 2016). The common tests are only run on the
    Windows Server 2016 build worker image. Helps with
    [issue #477](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/477).
- xGroup
  - Corrected style guideline violations. ([issue #485](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/485))
- xWindowsProcess
  - Corrected style guideline violations. ([issue #496](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/496))
- Changes to PSWSIISEndpoint.psm1
  - Fixes most PSScriptAnalyzer issues.
- Changes to xRegistry
  - Fixed an issue that fails to remove reg key when the `Key` is specified as
    common registry path.
    ([issue #444](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/444))
- Changes to xService
  - Added support for Group Managed Service Accounts
- Adds new Integration tests for MSFT_xDSCWebService and removes old
  Integration test file, MSFT_xDSCWebService.xxx.ps1.
- xRegistry
  - Corrected style guideline violations. ([issue #489](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/489))
- Fix script analyzer issues in UseSecurityBestPractices.psm1.
  [issue #483](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/483)
- Fixes script analyzer issues in xEnvironmentResource.
  [issue #484](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/484)
- Fixes script analyzer issues in MSFT_xMsiPackage.psm1.
  [issue #486](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/486)
- Fixes script analyzer issues in MSFT_xPackageResource.psm1.
  [issue #487](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/487)
- Adds spaces between variable types and variables, and changes Type
  Accelerators to Fully Qualified Type Names on affected code.
- Fixes script analyzer issues in MSFT_xPSSessionConfiguration.psm1
  and convert Type Accelerators to Fully Qualified Type Names
  [issue #488](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/488).
- Adds spaces between array members.
- Fixes script analyzer issues in MSFT_xRemoteFile.psm1 and
  correct general style violations.
  ([issue #490](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/490))
- Remove unnecessary whitespace from line endings.
- Add statement to README.md regarding the lack of testing of this module with
  PowerShell 4
  [issue #522](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/522).
- Fixes script analyzer issues in MSFT_xWindowsOptionalFeature.psm1 and
  correct general style violations.
  [issue #494](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/494))
- Fixes script analyzer issues in MSFT_xRemoteFile.psm1 missed from
  [issue #490](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/490).
- Fix script analyzer issues in MSFT_xWindowsFeature.psm1.
  [issue #493](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/493)
- Fix script analyzer issues in MSFT_xUserResource.psm1.
  [issue #492](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/492)
- Moves calls to set $global:DSCMachineStatus = 1 into a helper function to
  reduce the number of locations where we need to suppress PSScriptAnalyzer
  rules PSAvoidGlobalVars and PSUseDeclaredVarsMoreThanAssignments.
- Adds spaces between comment hashtags and comments.
- Fixes script analyzer issues in MSFT_xServiceResource.psm1.
  [issue #491](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/491)
- Fixes script analyzer issues in MSFT_xWindowsPackageCab.psm1.
  [issue #495](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/495)
- xFileUpload:
  - Fixes script analyzer issues in xFileUpload.schema.psm1.
    [issue #497](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/497)
  - Update to meet style guidelines.
  - Added Integration tests.
  - Updated manifest Author, Company and Copyright to match
    standards.
- Updated module manifest Copyright to match standards and remove
  year.
- Auto-formatted the module manifest to improve layout.
- Fix Run-On Words in README.md.
- Changes to xPackage
  - Fix an misnamed variable that causes an error during error message output.
    [issue #449](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/449))
- Fixes script analyzer issues in MSFT_xPSSessionConfiguration.psm1.
  [issue #566](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/566)
- Fixes script analyzer issues in xGroupSet.schema.psm1.
  [issue #498](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/498)
- Fixes script analyzer issues in xProcessSet.schema.psm1.
  [issue #499](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/499)
- Fixes script analyzer issues in xServiceSet.schema.psm1.
  [issue #500](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/500)
- Fixes script analyzer issues in xWindowsFeatureSet.schema.psm1.
  [issue #501](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/501)
- Fixes script analyzer issues in xWindowsOptionalFeatureSet.schema.psm1
  [issue #502](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/502)
- Updates Should statements in Pester tests to use dashes before parameters.
- Added a CODE\_OF\_CONDUCT.md with the same content as in the README.md
  [issue #562](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/562)
- Replaces Type Accelerators with fully qualified type names.

## [8.4.0.0] - 2018-07-25

### Changed

- Changes to xPSDesiredStateConfiguration
  - Opt-in for the common tests validate module files and script files.
  - All files change to encoding UTF-8 (without byte order mark).
  - Opt-in for the common test for example validation.
  - Added Visual Studio Code workspace settings that helps with formatting
    against the style guideline.
  - Update all examples for them to be able pass the common test validation.
- xEnvironment path documentation update demonstrating usage with multiple
  values
  ([issue #415](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/415).
  [Alex Kokkinos (@alexkokkinos)](https://github.com/alexkokkinos)
- Changes to xWindowsProcess
  - Increased the wait time in the integration tests since the tests
    still failed randomly
    ([issue #420](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/420)).
- Renamed and updated examples to be able to publish them to PowerShell
  Gallery.
  - Sample\_xScript.ps1 → xScript\_WatchFileContentConfig.ps1
  - Sample\_xService\_UpdateStartupTypeIgnoreState.ps1 →
    xService\_UpdateStartupTypeIgnoreStateConfig.ps1
  - Sample\_xWindowsProcess\_Start.ps1 →
    xWindowsProcess\_StartProcessConfig.ps1
  - Sample\_xWindowsProcess\_StartUnderUser.ps1 →
    xWindowsProcess\_StartProcessUnderUserConfig.ps1
  - Sample\_xWindowsProcess\_Stop.ps1 → xWindowsProcess\_StopProcessConfig.ps1
  - Sample\_xWindowsProcess\_StopUnderUser.ps1 →
    xWindowsProcess\_StopProcessUnderUserConfig.ps1
  - Sample\_xUser\_CreateUser.ps1.ps1 → xUser\_CreateUserConfig.ps1
  - Sample\_xUser\_Generic.ps1.ps1 → xUser\_CreateUserDetailedConfig.ps1
  - Sample\_xWindowsFeature.ps1 → xWindowsFeature\_AddFeatureConfig.ps1
  - Sample\_xWindowsFeatureSet\_Install.ps1 →
    xWindowsFeatureSet\_AddFeaturesConfig.ps1
  - Sample\_xWindowsFeatureSet\_Uninstall.ps1 →
    xWindowsFeatureSet\_RemoveFeaturesConfig.ps1
  - Sample\_xRegistryResource\_AddKey.ps1 → xRegistryResource\_AddKeyConfig.ps1
  - Sample\_xRegistryResource\_RemoveKey.ps1 →
    xRegistryResource\_RemoveKeyConfig.ps1
  - Sample\_xRegistryResource\_AddOrModifyValue.ps1 →
    xRegistryResource\_AddOrModifyValueConfig.ps1
  - Sample\_xRegistryResource\_RemoveValue.ps1 →
    xRegistryResource\_RemoveValueConfig.ps1
  - Sample\_xService\_CreateService.ps1 → xService\_CreateServiceConfig.ps1
  - Sample\_xService\_DeleteService.ps1 → xService\_RemoveServiceConfig.ps1
  - Sample\_xServiceSet\_StartServices.ps1 →
    xServiceSet\_StartServicesConfig.ps1
  - Sample\_xServiceSet\_BuiltInAccount →
    xServiceSet\_EnsureBuiltInAccountConfig.ps1
  - Sample\_xWindowsPackageCab → xWindowsPackageCab\_InstallPackageConfig
  - Sample\_xWindowsOptionalFeature.ps1 →
    xWindowsOptionalFeature\_EnableConfig.ps1
  - Sample\_xWindowsOptionalFeatureSet\_Enable.ps1 →
    xWindowsOptionalFeatureSet\_EnableConfig.ps1
  - Sample\_xWindowsOptionalFeatureSet\_Disable.ps1 →
    xWindowsOptionalFeatureSet\_DisableConfig.ps1
  - Sample\_xRemoteFileUsingProxy.ps1 →
    xRemoteFile\_DownloadFileUsingProxyConfig.ps1
  - Sample\_xRemoteFile.ps1 → xRemoteFile\_DownloadFileConfig.ps1
  - Sample\_xProcessSet\_Start.ps1 → xProcessSet\_StartProcessConfig.ps1
  - Sample\_xProcessSet\_Stop.ps1 → xProcessSet\_StopProcessConfig.ps1
  - Sample\_xMsiPackage\_UninstallPackageFromHttps.ps1 →
    xMsiPackage\_UninstallPackageFromHttpsConfig.ps1
  - Sample\_xMsiPackage\_UninstallPackageFromFile.ps1 →
    xMsiPackage\_UninstallPackageFromFileConfig.ps1
  - Sample\_xMsiPackage\_InstallPackageFromFile →
    xMsiPackage\_InstallPackageConfig.ps1
  - Sample\_xGroup\_SetMembers.ps1 → xGroup\_SetMembersConfig.ps1
  - Sample\_xGroup\_RemoveMembers.ps1 → xGroup\_RemoveMembersConfig.ps1
  - Sample\_xGroupSet\_AddMembers.ps1 → xGroupSet\_AddMembersConfig.ps1
  - Sample\_xFileUpload.ps1 → xFileUpload\_UploadToSMBShareConfig.ps1
  - Sample\_xEnvironment\_CreateMultiplePathVariables.ps1 →
    xEnvironment\_AddMultiplePathsConfig.ps1
  - Sample\_xEnvironment\_RemovePathVariables.ps1 →
    xEnvironment\_RemoveMultiplePathsConfig.ps1
  - Sample\_xEnvironment\_CreateNonPathVariable.ps1 →
    xEnvironment\_CreateNonPathVariableConfig.ps1
  - Sample\_xEnvironment\_Remove.ps1 → xEnvironment\_RemoveVariableConfig.ps1
  - Sample\_xArchive\_ExpandArchiveChecksumAndForce.ps1 →
    xArchive\_ExpandArchiveChecksumAndForceConfig.ps1
  - Sample\_xArchive\_ExpandArchiveDefaultValidationAndForce.ps1 →
    xArchive\_ExpandArchiveDefaultValidationAndForceConfig.ps1
  - Sample\_xArchive\_ExpandArchiveNoValidation.ps1 →
    xArchive\_ExpandArchiveNoValidationConfig.ps1
  - Sample\_xArchive\_ExpandArchiveNoValidationCredential.ps1 →
    xArchive\_ExpandArchiveNoValidationCredentialConfig.ps1
  - Sample\_xArchive\_RemoveArchiveChecksum.ps1 →
    xArchive\_RemoveArchiveChecksumConfig.ps1
  - Sample\_xArchive\_RemoveArchiveNoValidation.ps1 →
    xArchive\_RemoveArchiveNoValidationConfig.ps1
  - Sample\_InstallExeCreds\_xPackage.ps1 →
    xPackage\_InstallExeUsingCredentialsConfig.ps1
  - Sample\_InstallExeCredsRegistry\_xPackage.ps1 →
    xPackage\_InstallExeUsingCredentialsAndRegistryConfig.ps1
  - Sample\_InstallMSI\_xPackage.ps1 → xPackage\_InstallMsiConfig.ps1
  - Sample\_InstallMSIProductId\_xPackage.ps1 →
    xPackage\_InstallMsiUsingProductIdConfig.ps1
- New examples
  - xUser\_RemoveUserConfig.ps1
  - xWindowsFeature\_AddFeatureUsingCredentialConfig.ps1
  - xWindowsFeature\_AddFeatureWithLogPathConfig.ps1
  - xWindowsFeature\_RemoveFeatureConfig.ps1
  - xService\_ChangeServiceStateConfig.ps1
  - xWindowsOptionalFeature\_DisableConfig.ps1
  - xPSEndpoint\_NewConfig.ps1
  - xPSEndpoint\_NewWithDefaultsConfig.ps1
  - xPSEndpoint\_RemoveConfig.ps1
  - xPSEndpoint\_NewCustomConfig.ps1
- Removed examples
  - Sample\_xPSSessionConfiguration.ps1 - This file was split up in several
    examples, those starting with 'xPSEndpoint*'.
  - Sample\_xMsiPackage\_InstallPackageFromHttp - This was added to the example
    xMsiPackage\_InstallPackageConfig.ps1 so the example sows either URI
    scheme.
  - Sample\_xEnvironment\_CreatePathVariable.ps1 - Same as the new example
    xEnvironment\_AddMultiplePaths.ps1

## [8.3.0.0] - 2018-06-13

### Changed

- Changes to xPSDesiredStateConfiguration
  - README.md: Fixed typo.
    [Steve Banik (@stevebanik-ndsc)](https://github.com/stevebanik-ndsc)
  - Adding a Branches section to the README.md with Codecov badges for both
    master and dev branch
    ([issue #416](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/416)).
- Changes to xWindowsProcess
  - Integration tests for this resource should no longer fail randomly. A
    timing issue made the tests fail in certain scenarios
    ([issue #420](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/420)).
- Changes to xDSCWebService
  - Added the option to use a certificate based on it's subject and template
    name instead of it's thumbprint. Resolves
    [issue #205](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/205).
  - xDSCWebService: Fixed an issue where Test-WebConfigModulesSetting would
    return $true when web.config contains a module and the desired state was
    for it to be absent. Resolves
    [issue #418](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/418).
- Updated the main DSCPullServerSetup readme to read easier, then updates the
  PowerShell comment based help for each function to follow normal help
  standards. [James Pogran (@jpogran)](https://github.com/jpogran)
- xRemoteFile: Remove progress bar for file download. This resolves issues
  [#165](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/165)
  and
  [#383](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/383)
  [Claudio Spizzi (@claudiospizzi)](https://github.com/claudiospizzi)

## [8.2.0.0] - 2018-04-20

### Changed

- xDSCWebService: Disable installing
  Microsoft.Powershell.Desiredstateconfiguration.Service.Resources.dll as a
  temporary workaround since the binary is missing on the latest Windows
  builds.

## [8.1.0.0] - 2018-03-22

### Changed

- xDSCWebService: Enable SQL provider configuration

## [8.0.0.0] - 2017-11-15

### Changed

- xDSCWebService
  - BREAKING CHANGE: The Pull Server will now run in a 64 bit IIS process by
    default. Enable32BitAppOnWin64 needs to be set to TRUE for the Pull
    Server to run in a 32 bit process.

## [7.0.0.0] - 2017-08-23

### Changed

- xService
  - BREAKING CHANGE: The service will now return as compliant if the service
    is not installed and the StartupType is set to Disabled regardless of the
    value of the Ensure property.
- Fixed misnamed certificate thumbprint variable in example
  Sample_xDscWebServiceRegistrationWithSecurityBestPractices

## [6.4.0.0] - 2017-05-09

### Changed

- xGroup:
  - Added updates from PSDscResources:
    - Added support for domain based group members on Nano server

## [6.3.0.0] - 2017-05-01

### Changed

- xDSCWebService
  - Fixed an issue where all 64bit IIS application pools stop working after
    installing DSC Pull Server, because IISSelfSignedCertModule(32bit) module
    was registered without bitness32 precondition.

## [6.2.0.0] - 2017-04-19

### Changed

- xMsiPackage:
  - Created high quality MSI package manager resource
- xArchive:
  - Fixed a minor bug in the unit tests where sometimes the incorrect
    DateTime format was used.
- xWindowsFeatureSet:
  - Had the wrong parameter name in one test case.

## [6.1.0.0] - 2017-03-08

### Changed

- Moved DSC pull server setup tests to DSCPullServerSetup folder for new common
  tests.
- xArchive:
  - Updated the resource to be a high quality resource
  - Transferred the existing "unit" tests to integration tests
  - Added unit and end-to-end tests
  - Updated documentation and examples
- xUser
  - Fixed error handling in xUser
- xRegistry
  - Fixed bug where an error was thrown when running Get-DscConfiguration if
    the registry key already existed
- Updated Test-IsNanoServer cmdlet to properly test for a Nano server rather
  than the core version of PowerShell

## [6.0.0.0] - 2017-02-303

### Changed

- xEnvironment
  - Updated resource to follow HQRM guidelines.
  - Added examples.
  - Added unit and end-to-end tests.
  - Significantly cleaned the resource.
  - Minor Breaking Change where the resource will now throw an error if no
    value is provided, Ensure is set to present, and the variable does not
    exist, whereas before it would create an empty registry key on the
    machine in this case (if this is the desired outcome then use the
    Registry resource).
  - Added a new Write property 'Target', which specifies whether the user
    wants to set the machine variable, the process variable, or both
    (previously it was setting both in most cases).
- xGroup:
  - Group members in the "NT Authority", "BuiltIn" and "NT Service" scopes
    should now be resolved without an error. If you were seeing the errors
    "Exception calling ".ctor" with "4" argument(s): "Server names cannot
    contain a space character."" or "Exception calling ".ctor" with "2"
    argument(s): "Server names cannot contain a space character."", this fix
    should resolve those errors. If you are still seeing one of the errors,
    there is probably another local scope we need to add. Please let us know.
  - The resource will no longer attempt to resolve group members if Members,
    MembersToInclude, and MembersToExclude are not specified.

## [5.2.0.0] - 2017-01-26

### Changed

- xWindowsProcess
  - Minor updates to integration tests because one of the tests was flaky.
- xRegistry:
  - Added support for forward slashes in registry key names. This resolves
    issue
    [#285](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/285).

## [5.1.0.0] - 2017-12-17

### Changed

- xWindowsFeature:
  - Added Catch to ignore RuntimeException when importing ServerManager
    module. This resolves issue
    [#69](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/69).
  - Updated unit tests.
- xPackage:
  - No longer checks for package installation when a reboot is required. This
    resolves issue
    [#52](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/52).
  - Ensures a space is added to MSI installation arguments. This resolves
    issue
    [#195](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/195).
  - Adds RunAsCredential parameter to permit installing packages with
    specific user account. This resolves issue
    [#221](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/221).
  - Fixes null verbose log output error. This resolves issue
    [#224](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/224).
- xDSCWebService
  - Fixed issue where resource would fail to read redirection.config file.
    This resolves issue
    [#191](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/191)
- xArchive
  - Fixed issue where resource would throw exception when file name contains
    brackets. This resolves issue
    [#255](https://github.com/PowerShell/xPSDesiredStateConfiguration/issues/255).
- xScript
  - Cleaned resource for high quality requirements
  - Added unit tests
  - Added integration tests
  - Updated documentation and example
- ResourceSetHelper:
  - Updated common functions for all 'Set' resources.
  - Added unit tests
- xGroupSet:
  - Updated resource to use new ResouceSetHelper functions and added
    integration tests.
- xGroup:
  - Cleaned module imports, fixed PSSA issues, and set ErrorActionPreference
    to stop.
- xService:
  - Cleaned resource functions to enable StrictMode.
  - Fixed bug in which Set-TargetResource would create a service when Ensure
    set to Absent and Path specified.
  - Added unit tests.
  - Added integration tests for BuiltInAccount and Credential.
- xServiceSet:
  - Updated resource to use new ResouceSetHelper functions and added
    integration tests.
  - Updated documentation and example
- xWindowsProcess
  - Cleaned resource as per high quality guidelines.
  - Added unit tests.
  - Added integration tests.
  - Updated documentation.
  - Updated examples.
  - Fixed bug in Get-TargetResource.
  - Added a 'Count' value to the hashtable returned by Get-TargetResource so
    that the user can see how many instances of the process are running.
  - Fixed bug in finding the path to the executable.
  - Changed name to be xWindowsProcess everywhere.
- xWindowsOptionalFeatureSet
  - Updated resource to use new ResouceSetHelper functions and added
    integration tests.
  - Updated documentation and examples
- xWindowsFeatureSet
  - Updated resource to use new ResouceSetHelper functions and added
    integration tests.
  - Updated documentation and examples
- xProcessSet
  - Updated resource to use new ResouceSetHelper functions and added
    integration tests.
  - Updated documentation and examples
- xRegistry
  - Updated resource to be high-quality
  - Fixed bug in which the user could not set a Binary registry value to 0
  - Added unit and integration tests
  - Added examples and updated documentation

## [5.0.0.0] - 2017-11-02

### Changed

- xWindowsFeature:
  - Cleaned up resource (PSSA issues, formatting, etc.)
  - Added/Updated Tests and Examples
  - BREAKING CHANGE: Removed the unused Source parameter
  - Updated to a high quality resource
- xDSCWebService:
  - Add DatabasePath property to specify a custom database path and enable
    multiple pull server instances on one server.
  - Rename UseUpToDateSecuritySettings property to UseSecurityBestPractices.
  - Add DisableSecurityBestPractices property to specify items that are
    excepted from following best practice security settings.
- xGroup:
  - Fixed PSSA issues
  - Formatting updated as per style guidelines
  - Missing comment-based help added for Get-/Set-/Test-TargetResource
  - Typos fixed in Unit test script
  - Unit test 'Get-TargetResource/Should return hashtable with correct values
    when group has no members' updated to handle the expected empty Members
    array correctly
  - Added a lot of unit tests
  - Cleaned resource
- xUser:
  - Fixed PSSA/Style violations
  - Added/Updated Tests and Examples
- Added xWindowsPackageCab
- xService:
  - Fixed PSSA/Style violations
  - Updated Tests
  - Added 'Ignore' state

## [4.0.0.0] - 2017-09-21

### Changed

- xDSCWebService:
  - Added setting of enhanced security
  - Cleaned up Examples
  - Cleaned up pull server verification test
- xProcess:
  - Fixed PSSA issues
  - Corrected most style guideline issues
- xPSSessionConfiguration:
  - Fixed PSSA and style issues
  - Renamed internal functions to follow verb-noun formats
  - Decorated all functions with comment-based help
- xRegistry:
  - Fixed PSSA and style issues
  - Renamed internal functions to follow verb-noun format
  - Decorated all functions with comment-based help
  - Merged with in-box Registry
  - Fixed registry key and value removal
  - Added unit tests
- xService:
  - Added descriptions to MOF file.
  - Added additional details to parameters in Readme.md in a format that can
    be generated from the MOF.
  - Added DesktopInteract parameter.
  - Added standard help headers to *-TargetResource functions.
  - Changed indent/format of all function help headers to be consistent.
  - Fixed line length violations.
  - Changed localization code so only a single copy of localization strings
    are required.
  - Removed localization strings from inside module file.
  - Updated unit tests to use standard test enviroment configuration and
    header.
  - Recreated unit tests to be non-destructive.
  - Created integration tests.
  - Allowed service to be restarted immediately rather than wait for next LCM
    run.
  - Changed helper function names to valid verb-noun format.
  - Removed New-TestService function from
    MSFT_xServiceResource.TestHelper.psm1 because it should not be used.
  - Fixed error calling Get-TargetResource when service does not exist.
  - Fixed bug with Get-TargetResource returning StartupType 'Auto' instead of
    'Automatic'.
  - Converted to HQRM standards.
  - Removed obfuscation of exception in Get-Win32ServiceObject function.
  - Fixed bug where service start mode would be set to auto when it already
    was set to auto.
  - Fixed error message content when start mode can not be changed.
  - Removed shouldprocess from functions as not required.
  - Optimized Test-TargetResource and Set-TargetResource by removing repeated
    calls to Get-Service and Get-CimInstance.
  - Added integration test for testing changes to additional service
    properties as well as changing service binary path.
  - Modified Set-TargetResource so that newly created service created with
    minimal properties and then all additional properties updated
    (simplification of code).
  - Added support for changing Service Description and DisplayName
    parameters.
  - Fixed bug when changing binary path of existing service.
- Removed test log output from repo.
- xWindowsOptionalFeature:
  - Cleaned up resource (PSSA issues, formatting, etc.)
  - Added example script
  - Added integration test
  - BREAKING CHANGE: Removed the unused Source parameter
  - Updated to a high quality resource
- Removed test log output from repo.
- Removed the prefix MSFT_ from all files and folders of the composite
  resources in this module because they were unavailable to Get-DscResource and
  Import-DscResource.
  - xFileUpload
  - xGroupSet
  - xProcessSet
  - xServiceSet
  - xWindowsFeatureSet
  - xWindowsOptionalFeatureSet

## [3.13.0.0] - 2017-10-08

### Changed

- Converted appveyor.yml to install Pester from PSGallery instead of from
  Chocolatey.
- Updated appveyor.yml to use the default image.
- Merged xPackage with in-box Package resource and added tests.
- xPackage: Re-implemented parameters for installation check from registry key
  value.
- xGroup:
  - Fixed Verbose output in Get-MembersAsPrincipals function.
  - Fixed bug when credential parameter passed does not contain local or
    domain context.
  - Fixed logic bug in MembersToInclude and MembersToExclude.
  - Fixed bug when trying to include the built-in Administrator in Members.
  - Fixed bug where Test-TargetResource would check for members when none
    specified.
  - Fix bug in Test-TargetResourceOnFullSKU function when group being set to
    a single member.
  - Fix bug in Set-TargetResourceOnFullSKU function when group being set to a
    single member.
  - Fix bugs in Assert-GroupNameValid to throw correct exception.
- xService
  - Updated xService resource to allow empty string for Description
    parameter.
- Merged xProcess with in-box Process resource and added tests.
- Fixed PSSA issues in xPackageResource.

## [3.12.0.0] - 2017-06-30

### Changed

- Removed localization for now so that resources can run on non-English
  systems.

## [3.11.0.0] - 2017-06-29

### Changed

- xRemoteFile:
  - Added parameters:
    - TimeoutSec
    - Proxy
    - ProxyCredential
  - Added unit tests.
  - Corrected Style Guidelines issues.
  - Added Localization support.
  - URI parameter supports File://.
  - Get-TargetResource returns URI parameter.
  - Fixed logging of error message reported when download fails.
  - Added new example Sample_xRemoteFileUsingProxy.ps1.
- Examples: Fixed missing newline at end of PullServerSetupTests.ps1.
- xFileUpload: Added PSSA rule suppression attribute.
- xPackageResource: Removed hardcoded ComputerName 'localhost' parameter from
  Get-WMIObject to eliminate PSSA rule violation. The parameter is not
  required.
- Added .gitignore to prevent DSCResource.Tests from being commited to repo.
- Updated AppVeyor.yml to use WMF 5 build OS so that latest test methods work.
- Updated xWebService resource to not deploy Devices.mdb if esent provider is
  used
- Fixed $script:netsh parameter initialization in xWebService resource that was
  causing CIM exception when EnableFirewall flag was specified.
- xService:
  - Fixed a bug where, despite no state specified in the config, the resource
    test returns false if the service is not running
  - Fixed bug in which Automatice StartupType did not match the 'Auto'
    StartMode in Test-TargetResource.
- xPackage: Fixes bug where CreateCheckRegValue was not being removed when
  uninstalling packages
- Replaced New-NetFirewallRule cmdlets with netsh as this cmdlet is not
  available by default on some downlevel OS such as Windows 2012 R2 Core.
- Added the xEnvironment resource
- Added the xWindowsFeature resource
- Added the xScript resource
- Added the xUser resource
- Added the xGroupSet resource
- Added the xProcessSet resource
- Added the xServiceSet resource
- Added the xWindowsFeatureSet resource
- Added the xWindowsOptionalFeatureSet resource
- Merged the in-box Service resource with xService and added tests for xService
- Merged the in-box Archive resource with xArchive and added tests for xArchive
- Merged the in-box Group resource with xGroup and added tests for xGroup

## [3.10.0.0] - 2016-05-18

### Changed

- **Publish-ModuleToPullServer**
- **Publish-MOFToPullServer**

## [3.9.0.0] - 2016-03-31

### Changed

- Added more information how to use Publish-DSCModuleAndMof cmdlet and samples
- Removed compliance server samples

## [3.8.0.0] - 2016-03-13

### Changed

- Added Pester tests to validate pullserver deployement.
- Removed Compliance Server deployment from xWebservice resource. Fixed
  database provider selection issue depending on OS flavor
- Added Publish-DSCModuleAndMof cmdlet to package DSC modules and mof and
  publish them on DSC enterprise pull server
- xRemoteFile resource: Added size verification in cache

## [3.7.0.0] - 2016-02-03

### Changed

- xService:
  - Fixed a bug where 'Dependencies' property was not picked up and caused
    exception when set.
- xWindowsOptionalFeature:
  - Fixed bug where Test-TargetResource method always failed.
  - Added support for Windows Server 2012 (and later) SKUs.
- Added xRegistry resource

## [3.6.0.0] - 2015-12-03

### Changed

- Added CreateCheckRegValue parameter to xPackage resource
- Added MatchSource parameter to xRemoteFile resource

## [3.5.0.0] - 2015-09-11

### Changed

- MSFT_xPackageResource: Added ValidateSet to Get/Set/Test-TargetResource to
  match MSFT_xPackageResource.schema.mof
- Fixed bug causing xService to throw error when service already exists
- Added StartupTimeout to xService resource
- Removed UTF8 BOM
- Added code for pull server removal

## [3.4.0.0] - 2015-07-24

### Changed

- Added logging inner exception messages in xArchive and xPackage resources
- Fixed hash calculation in Get-CacheEntry
- Fixed issue with PSDSCComplianceServer returning HTTP Error 401.2

## [3.3.0.0] - 2015-06-09

### Changed

- Add support to xPackage resource for checking different registry hives
- Added support for new registration properties in xDscWebService resource

## [3.2.0.0] - 2015-05-02

### Changed

- xArchive:
  - Fix problems with file names containing square brackets.
- xDSCWebService:
  - Fix default culture issue.
- xPackage:
  - Security enhancements.

## [3.0.3.4] - 2014-12-18

### Changed

- Multiple issues addressed
  - Corrected output type for Set- and Test-TargetResource functions in
    xWebSite, xPackage, xArchive, xGroup, xProcess, xService
  - xRemoteFile modified to support creating a directory that does not exist
    when specified, ensuring idempotency. Also improved error messages.
  - xDSCWebService updated so that Get-TargetResource returns the OData
    Endpoint URL correctly.
  - In xWindowsOptionalFeature, fixed Test-TargetResource issue requiring
    Ensure = True. Note: this change requires the previous Ensure values of
    Enable and Disable to change to Present and Absent

## [3.0.2.0] - 2014-08-22

### Changed

- Adding following resources:
  - xGroup

## [3.0.1.0] - 2017-07-22

### Changed

- Adding following resources:
  - xFileUpload

## [2.0.0.0] - 2017-08-04

### Changed

- Adding following resources:
  - xWindowsProcess
  - xService
  - xRemoteFile
  - xPackage

## [1.1.0.0] - 2017-08-04

### Changed

- Fix to remove and recreate the SSL bindings when performing a new HTTPS IIS
  Endpoint setup.
- Fix in the resource module to consume WebSite Name parameter correctly

## [1.0.0.0] - 2017-08-04

### Changed

- Initial release with the following resources:
  - DscWebService
