# Changelog

This file contains the changelog for the ExtendedLocalCoverage package. It follows the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## Unreleased

## [0.1.3] - 2025-09-29

### Added
- Forward property access from `WrappedPackageCoverage` to `PackageCoverage`.
- Wrap `LocalCoverage.generate_coverage` in a try-catch block to handle the issue with PrettyTables v3.

## [0.1.2] - 2025-09-25

### Fixed
- Added some logic to handle PrettyTables v3, which could be loaded by the package under test ignoring the compat bound of LocalCoverage.jl.
  - The issue is on the `show` method of the `PackageCoverage` struct. This package now wraps the `PackageCoverage` struct to add a custom `WrappedPackageCoverage` struct which provides a custom `show` method.

## [0.1.1] - 2025-06-13

### Fixed
- Removed an error when trying to parse the extensions of the package under test.

## [0.1.0] - 2025-01-06
Initial release
