# ExtendedLocalCoverage

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://disberd.github.io/ExtendedLocalCoverage.jl/stable)
[![In development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://disberd.github.io/ExtendedLocalCoverage.jl/dev)
[![Build Status](https://github.com/disberd/ExtendedLocalCoverage.jl/workflows/Test/badge.svg)](https://github.com/disberd/ExtendedLocalCoverage.jl/actions)
[![Test workflow status](https://github.com/disberd/ExtendedLocalCoverage.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/disberd/ExtendedLocalCoverage.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Lint workflow Status](https://github.com/disberd/ExtendedLocalCoverage.jl/actions/workflows/Lint.yml/badge.svg?branch=main)](https://github.com/disberd/ExtendedLocalCoverage.jl/actions/workflows/Lint.yml?query=branch%3Amain)
[![Docs workflow Status](https://github.com/disberd/ExtendedLocalCoverage.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/disberd/ExtendedLocalCoverage.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/disberd/ExtendedLocalCoverage.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/disberd/ExtendedLocalCoverage.jl)
[![DOI](https://zenodo.org/badge/DOI/FIXME)](https://doi.org/FIXME)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)
[![All Contributors](https://img.shields.io/github/all-contributors/disberd/ExtendedLocalCoverage.jl?labelColor=5e1ec7&color=c0ffee&style=flat-square)](#contributors)
[![BestieTemplate](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/JuliaBesties/BestieTemplate.jl/main/docs/src/assets/badge.json)](https://github.com/JuliaBesties/BestieTemplate.jl)

This package simply extends the functionality of [LocalCoverage.jl](https://github.com/JuliaBesties/LocalCoverage.jl) by adding the following features:
- Automatically extract the source files for the provided package using `Revise.parse_pkg_files`.
- Automatically create an xml cobertura coverage and an html report using `pycobertura`.
  - The `pycobertura` library is automatically installed and used thanks to `CondaPkg.jl` and `PythonCall.jl`, not requiring the user to manually install python or `lcov` which is only available on non-windows systems.

## How to Cite

If you use ExtendedLocalCoverage.jl in your work, please cite using the reference given in [CITATION.cff](https://github.com/disberd/ExtendedLocalCoverage.jl/blob/main/CITATION.cff).

## Contributing

If you want to make contributions of any kind, please first that a look into our [contributing guide directly on GitHub](docs/src/90-contributing.md) or the [contributing page on the website](https://disberd.github.io/ExtendedLocalCoverage.jl/dev/90-contributing/)

---

### Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
