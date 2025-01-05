module ExtendedLocalCoverage

using LocalCoverage: LocalCoverage, write_lcov_to_xml, pkgdir
using Revise: Revise, parse_pkg_files
using PythonCall: PythonCall, pyimport, pycall
using TOML: TOML, tryparsefile
import Pkg


export generate_package_coverage, generate_html_report

function extract_package_info(pkg_dir)
    project_toml = TOML.tryparsefile(joinpath(pkg_dir, "Project.toml"))
    pkg_name = project_toml["name"]
    pkg_uuid = project_toml["uuid"] |> Base.UUID
    pkg_id = Base.PkgId(pkg_uuid, pkg_name)
    return (; pkg_name, pkg_uuid, pkg_id)
end

function extract_included_files(pkg_id::Base.PkgId)
    # We always import the package in Main to make sure the Revise can find the source files
    Base.eval(Main, :(import $(Symbol(pkg_id.name))))
    pkgfiles = parse_pkg_files(pkg_id)
    return unique(pkgfiles.info.files)
end

"""
    generate_html_report(cobertura_file, html_file; title = nothing, pkg_dir = nothing)

Generate an HTML report from a cobertura XML file using the `pycobertura` Python package.

The `cobertura_file` and `html_file` arguments are the full paths to the cobertura XML file used as input and of the HTML file to be generated, respectively.

# Keyword arguments

- `title = "Package Coverage Report"` is the title used at the top of the HTML report.
- `pkg_dir = dirname(cobertura_file)` is the directory of the package being covered. It is used to generate the source code links in the HTML report and by default assumes the package directory to be the directory of the cobertura XML file.
"""
function generate_html_report(cobertura_file, html_file; title = "Package Coverage Report", pkg_dir = dirname(cobertura_file))
    (; filesystem_factory) = pyimport("pycobertura.filesystem")
    pycob = pyimport("pycobertura")
    cobertura = pycob.Cobertura(cobertura_file, filesystem=filesystem_factory(pkg_dir))
    reporter = pycall(pycob.reporters.HtmlReporter, cobertura; title)
    report = reporter.generate()
    open(html_file, "w") do io
        print(io, report)
    end
end

"""
    generate_package_coverage(pkg = nothing; run_test=true, test_args=[""], exclude = [], html_name = "index.html", cobertura_name = "cobertura-coverage.xml", print_to_stdout = true)

Generate a summary of coverage results for package `pkg`.

If no `pkg` is supplied, the method operates in the currently active package.
This acts similary to (and based on) the `generate_coverage` function from [LocalCoverage.jl](https://github.com/JuliaCI/LocalCoverage.jl), but providing two main differences:
- It automatically extracts the list of files included by the package using `Revise.parse_pkg_files`.
- It allows to generate an HTML report (does so by default) using the `pycobertura` Python package which is installed by default via CondaPkg.
  - In contrast, the HTML report from `LocalCoverage.jl` relies on lcov being already available on your system and does not work on Windows machines.

# Keyword arguments (and their defaults)

- `run_test = true` this is forwarded to `LocalCoverage.generate_coverage` and determines whether tests are executed. When `false`, test execution
step is skipped allowing an easier use in combination with other test packages.

- `test_args = [""]` is passed on to `Pkg.test`.

- `exclude = []` is used to specify string or regexes that are used to filter out some of the files in the list of package includes. The exclusion is done by removing from the list of files all files for which `occursin(needle, filename)` returns `true`, where `needle` is any element of `exclude`.

- `html_name = "index.html"` is the name of the HTML file to be generated. If nothing is provided, no HTML report is generated. The report is always generated in the `coverage` subdirectory of the target package directory.

- `cobertura_name = "cobertura-coverage.xml"` is the name of the cobertura XML file to be generated. If nothing is provided both to this kwarg and to `html_name`, no cobertura XML file is generated. The file is always generated in the `coverage` subdirectory of the target package directory.

- `print_to_stdout = true` determines whether the coverage summary is printed to the standard output.

# Return values

The function returns a named tuple with the following fields:

- `cov` the coverage summary as returned by `LocalCoverage.generate_coverage`.
- `cobertura_file` the full path to the cobertura XML file, if any was generated.
- `html_file` the full path to the HTML file, if any was generated.
"""
function generate_package_coverage(pkg = nothing; run_test=true, test_args=[""], exclude = [], html_name = "index.html", cobertura_name = "cobertura-coverage.xml", print_to_stdout = true)
    pkg_dir = pkgdir(pkg)
    (; pkg_name, pkg_id) = extract_package_info(pkg_dir)
    file_list = extract_included_files(pkg_id)
    filter!(file_list) do filename
        for needle in exclude
            occursin(needle, filename) && return false
        end
        return true
    end
    # Generate the coverage
    cov = LocalCoverage.generate_coverage(pkg; run_test, test_args, folder_list=[], file_list)
    if print_to_stdout
        show(IOContext(stdout, :print_gaps => true), cov)
    end
    # Create the cobertura xml file
    coverage_dir = joinpath(pkg_dir, "coverage")
    lcov_file = joinpath(coverage_dir, "lcov.info")
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
        generate_html_report(cobertura_file, html_file; title = pkg_name * " coverage report", pkg_dir)
    end
    return (; cov, cobertura_file, html_file)
end

end