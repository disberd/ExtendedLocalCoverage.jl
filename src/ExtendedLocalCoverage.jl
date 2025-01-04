module ExtendedLocalCoverage

using LocalCoverage: LocalCoverage, write_lcov_to_xml, pkgdir, generate_coverage
using Revise: Revise, parse_pkg_files
using PythonCall: PythonCall, pyimport, pycall
using TOML: TOML, tryparsefile
import Pkg


export generate_extended_coverage

pycobertura() = pyimport("pycobertura")

function generate_extended_coverage(pkg = nothing; run_test=true, test_args=[""], exclude = [])
    pkg_dir = pkgdir(pkg)
    project_toml = TOML.tryparsefile(joinpath(pkg_dir, "Project.toml"))
    pkg_name = project_toml["name"]
    pkg_uuid = project_toml["uuid"] |> Base.UUID
    pkg_id = Base.PkgId(pkg_uuid, pkg_name)
    if !haskey(Base.loaded_modules, pkg_id)
        @warn "The target package $pkg_name is not loaded. Loading it to correctly extract the source files."
        Base.eval(Main, :(import $(Symbol(pkg_name))))
    end
    pkgfiles = parse_pkg_files(pkg_id)
    file_list = deepcopy(pkgfiles.info.files) |> unique
    filter!(file_list) do filename
        for needle in exclude
            occursin(needle, filename) && return false
        end
        return true
    end
    # Generate the coverage
    generate_coverage(pkg; run_test, test_args, folder_list=[], file_list)
    # Create the cobertura xml file
    coverage_dir = joinpath(pkg_dir, "coverage")
    lcov_file = joinpath(coverage_dir, "lcov.info")
    cobertura_file = joinpath(coverage_dir, "cobertura-coverage.xml")
    html_file = joinpath(coverage_dir, "coverage.html")
    write_lcov_to_xml(cobertura_file, lcov_file)
    # Create the cobertura html file with source code
    (; filesystem_factory) = pyimport("pycobertura.filesystem")
    pycob = pycobertura()
    cobertura = pycob.Cobertura(cobertura_file, filesystem=filesystem_factory(pkg_dir))
    reporter = pycall(pycob.reporters.HtmlReporter, cobertura; title = pkg_name * "coverage report")
    report = reporter.generate()
    open(html_file, "w") do io
        print(io, report)
    end
    return cobertura_file, html_file
end

end