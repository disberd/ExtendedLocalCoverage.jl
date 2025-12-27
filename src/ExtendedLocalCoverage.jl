module ExtendedLocalCoverage

using LocalCoverage:
    LocalCoverage,
    write_lcov_to_xml,
    pkgdir,
    eval_coverage_metrics,
    PackageCoverage,
    FileCoverageSummary,
    format_gaps
using HypertextTemplates: HypertextTemplates, @component, @deftag, @render, @text
using HypertextTemplates.Elements:
    Elements,
    @a,
    @body,
    @div,
    @footer,
    @h1,
    @h2,
    @head,
    @header,
    @html,
    @meta,
    @span,
    @strong,
    @style,
    @table,
    @tbody,
    @td,
    @th,
    @thead,
    @title,
    @tr
using JuliaSyntaxHighlighting: JuliaSyntaxHighlighting, highlight
using Revise: Revise, parse_pkg_files
using TOML: TOML, tryparsefile
using CoverageTools: CoverageTools, LCOV
import Pkg
using StyledStrings: StyledStrings, AnnotatedString


export generate_package_coverage, generate_html_report, generate_native_html_report

# This is a temporary fix to fix PrettyTables issues until https://github.com/JuliaCI/LocalCoverage.jl/pull/68 is merged.
include("show_fix.jl")

# Native Julia HTML report generation (without Python dependencies)
include("html_report.jl")

function extract_package_info(pkg_dir)
    project_toml = TOML.tryparsefile(joinpath(pkg_dir, "Project.toml"))
    pkg_name = project_toml["name"]
    pkg_uuid = project_toml["uuid"] |> Base.UUID
    pkg_extensions = get(Dict{String,Any}, project_toml, "extensions") |> keys
    pkg_id = Base.PkgId(pkg_uuid, pkg_name)
    return (; pkg_name, pkg_uuid, pkg_id, pkg_extensions)
end

function extract_included_files(pkg_id::Base.PkgId)
    # We always import the package in Main to make sure the Revise can find the source files
    Base.eval(Main, :(import $(Symbol(pkg_id.name))))
    pkgfiles = parse_pkg_files(pkg_id)
    return unique(pkgfiles.info.files)
end

"""
    generate_package_coverage(pkg = nothing; kwargs...)

Generate a summary of coverage results for package `pkg`.

If no `pkg` is supplied, the method operates in the currently active package.
This acts similary to (and based on) the `generate_coverage` function from [LocalCoverage.jl](https://github.com/JuliaCI/LocalCoverage.jl), but providing two main differences:
- It automatically extracts the list of files included by the package using `Revise.parse_pkg_files`.
- It allows to generate an HTML report (does so by default) using the `pycobertura` Python package which is installed by default via CondaPkg.
  - In contrast, the HTML report from `LocalCoverage.jl` relies on lcov being already available on your system and does not work on Windows machines.

# Keyword arguments (and their defaults)

 - `use_existing_lcov = false` if true, the coverage is assumed to be already computed and available in `coverage/lcov.info` within the package directory. If false, the coverage is generated from scratch calling `LocalCoverage.generate_coverage`.

- `run_test = true` this is forwarded to `LocalCoverage.generate_coverage` and determines whether tests are executed. When `false`, test execution step is skipped allowing an easier use in combination with other test packages.

- `test_args = [""]` this is forwarded to `LocalCoverage.generate_coverage` and is there passed on to `Pkg.test`.

- `exclude = []` is used to specify string or regexes that are used to filter out some of the files in the list of package includes. The exclusion is done by removing from the list of files all files for which `occursin(needle, filename)` returns `true`, where `needle` is any element of `exclude`.

- `html_name = "index.html"` is the name of the HTML file to be generated. If nothing is provided, no HTML report is generated. The report is always generated in the `coverage` subdirectory of the target package directory.

- `cobertura_name = "cobertura-coverage.xml"` is the name of the cobertura XML file to be generated. If nothing is provided both to this kwarg and to `html_name`, no cobertura XML file is generated. The file is always generated in the `coverage` subdirectory of the target package directory.

- `print_to_stdout = true` determines whether the coverage summary is printed to the standard output.

- `extensions = true` when `true`, also tries to add to the coverage files in the `ext` directory that match an extension name specified in the `Project.toml` file.

# Return values

The function returns a named tuple with the following fields:

- `cov` the coverage summary as returned by `LocalCoverage.generate_coverage`.
- `cobertura_file` the full path to the cobertura XML file, if any was generated.
- `html_file` the full path to the HTML file, if any was generated.
"""
function generate_package_coverage(
    pkg = nothing;
    use_existing_lcov = false,
    run_test = true,
    test_args = [""],
    exclude = [],
    html_name = "index.html",
    cobertura_name = "cobertura-coverage.xml",
    print_to_stdout = true,
    extensions = true,
)
    pkg_dir = pkgdir(pkg)
    (; pkg_name, pkg_id, pkg_extensions) = extract_package_info(pkg_dir)
    coverage_dir = joinpath(pkg_dir, "coverage")
    lcov_file = joinpath(coverage_dir, "lcov.info")
    # Generate the coverage
    cov =
        if use_existing_lcov
            coverage = LCOV.readfile(lcov_file)
            eval_coverage_metrics(coverage, pkg_dir)
        else
            file_list = extract_included_files(pkg_id)
            extensions && maybe_add_extensions!(file_list, pkg_extensions, pkg_dir)
            filter!(file_list) do filename
                for needle in exclude
                    occursin(needle, filename) && return false
                end
                return true
            end
            try
                LocalCoverage.generate_coverage(
                    pkg;
                    run_test,
                    test_args,
                    folder_list = [],
                    file_list,
                )
            catch e # We do this, as the problem with PrettyTables causes an error from within the catch block in LocalCoverage.
                rethrow()
            end
        end |> WrappedPackageCoverage
    if print_to_stdout
        show(IOContext(stdout, :print_gaps => true), cov)
    end
    cobertura_file = if isnothing(cobertura_name) && isnothing(html_name)
        nothing
    else
        joinpath(coverage_dir, @something(cobertura_name, "cobertura-coverage.xml"))
    end
    html_file = isnothing(html_name) ? nothing : joinpath(coverage_dir, html_name)
    if !isnothing(cobertura_file)
        write_lcov_to_xml(cobertura_file, lcov_file)
    end
    # Create the cobertura html file with source code
    if !isnothing(html_file)
        generate_html_report(
            lcov_file,
            html_file;
            title = pkg_name * " coverage report",
            pkg_dir,
        )
    end
    return (; cov, cobertura_file, html_file)
end

function maybe_add_extensions!(files_list, pkg_extensions, pkg_dir)
    (isnothing(pkg_extensions) || isempty(pkg_extensions)) && return files_list
    for (path, dir, files) in walkdir("ext")
        for file in files
            endswith(file, ".jl") || continue
            noext_name = chopsuffix(file, ".jl")
            if noext_name in pkg_extensions || basename(path) in pkg_extensions
                rel_path = relpath(joinpath(path, file), pkg_dir)
                push!(files_list, rel_path)
            end
        end
    end
    unique!(files_list)
    return nothing
end

end