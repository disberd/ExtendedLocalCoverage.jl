# Changelog

This file contains the changelog for the ExtendedLocalCoverage package. It follows the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

## Unreleased

## [0.2.2] - 2026-06-23

### Added
- `generate_package_coverage` now accepts a `julia_args` keyword (a vector of strings, like `test_args`) that is forwarded to the julia process `Pkg.test` spawns for the test run. The main use case is `julia_args = ["--heap-size-hint=6G"]` to bound the test process' GC heap on memory-limited CI runners and avoid OOM kills. `LocalCoverage.generate_coverage` does not forward `julia_args`, so the test run is now driven via `Pkg.test` directly.
- The `EXTENDEDLOCALCOVERAGE_HEAP_SIZE_HINT` environment variable, when set (e.g. `6G`), adds `--heap-size-hint=<value>` to the test process' `julia_args`, making the hint configurable from CI without changing the call site. An explicit `--heap-size-hint` in `julia_args` takes precedence.

## [0.2.1] - 2026-06-23

### Fixed
- Fixed a `StringIndexError` in the HTML line-coverage report (`highlighted_lines`, `JuliaSyntaxHighlighting` extension) when a source file used CRLF line endings and had a multibyte Unicode character (e.g. `π`) right before the `\r`. The trailing `\r` is now stripped with `chop` instead of byte-based indexing.

## [0.2.0] - 2026-01-05

### Added
- The HTML coverage report is now generated natively in Julia (via `HypertextTemplates`) as a self-contained static page, replacing the previous report based on the Python `pycobertura` package.
- Optional Julia syntax highlighting of the source code in the HTML report through a `JuliaSyntaxHighlighting` package extension (with a `StyledStrings` extension for rendering), available on Julia 1.12+.

### Removed
- Dropped the `PythonCall` and `CondaPkg` dependencies (no Python/Conda environment is needed anymore).
- Removed the `WrappedPackageCoverage` `show` wrapper and the `PrettyTables` dependency, as the upstream `PrettyTables` v3 issue was fixed.

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
