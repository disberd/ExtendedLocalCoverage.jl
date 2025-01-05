```@meta
CurrentModule = ExtendedLocalCoverage
```

# ExtendedLocalCoverage

Documentation for [ExtendedLocalCoverage](https://github.com/disberd/ExtendedLocalCoverage.jl).

This package extends the functionality of [LocalCoverage](https://github.com/JuliaCI/LocalCoverage.jl) by providing a [`generate_package_coverage`](@ref) which calculate local coverage using `LocalCoverage.generate_coverage` but providing the following different features:
- It exploits `Revise` to automatically extract the included files in the target package and only checks coverage on those files.
- It uses `pycobertura` (installed via [CondaPkg.jl](https://github.com/cjdoris/CondaPkg.jl)) to generate the coverage report in HTML format.
  - This does not require users to have lcov installed on their system and also works on Windows machines.

The main reason for the creation of this package is simplifying assessing coverage on private repositories (specifically on gitlab) which do not have easy access to tools like [codecov](https://about.codecov.io/).

You can check an example of the resulting coverage report [at this page](https://disberd.github.io/ExtendedLocalCoverage.jl/coverage)

## Contributors

```@raw html
<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
```
