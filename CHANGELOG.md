# Change log for NetworkingDSc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- None

### Changed

- DefaultGatewayAddress:
  - Refactored to reduce code duplication.
  - Fixed hash table style violations - fixes [Issue #429](https://github.com/PowerShell/NetworkingDsc/issues/429).
  - Fixed general style violations.
- Added `.gitattributes` to ensure CRLF is used when pulling repository - Fixes
  [Issue #430](https://github.com/PowerShell/NetworkingDsc/issues/430).
- BREAKING CHANGE: Changed resource prefix from MSFT to DSC.
- Updated to use continuous delivery pattern using Azure DevOps - Fixes
  [Issue #435](https://github.com/PowerShell/NetworkingDsc/issues/435).

### Deprecated

- None

### Removed

- None

### Fixed

- None

### Security

- None
