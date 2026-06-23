@testitem "ExtendedLocalCoverage.jl" begin
    using ExtendedLocalCoverage: PackageCoverage
    import Pkg

    function clean_coverage(dir)
        isdir(dir) && rm(dir, recursive = true, force = true)
        nothing
    end

    CoverageTest_dir = joinpath(@__DIR__, "CoverageTest")

    current_proj = dirname(Base.active_project())
    Pkg.activate(CoverageTest_dir)
    try
        cov, xml, html =
            generate_package_coverage("CoverageTest"; exclude = ["foo", r"bar"])
        @test dirname(xml) |> endswith("coverage")
        @test isfile(xml)
        @test isfile(html)

        xml_content = read(xml, String)
        html_content = read(html, String)

        for text in (xml_content, html_content)
            @test contains(text, joinpath("src", "CoverageTest.jl"))
            @test !contains(text, joinpath("src", "foo.jl"))
            @test !contains(text, joinpath("src", "exclude_bar.jl"))
        end

        coverage_dir = dirname(xml)
        clean_coverage(coverage_dir)
        @test !isdir(coverage_dir)

        cov, xml_path, html_path =
            generate_package_coverage("CoverageTest"; html_name = nothing)
        @test isdir(coverage_dir)
        @test xml_path === joinpath(coverage_dir, "cobertura-coverage.xml")
        @test html_path === nothing
        @test isfile(xml_path)
        @test all(!endswith(".html"), readdir(coverage_dir))

        clean_coverage(coverage_dir)
        @test !isdir(coverage_dir)
        cov, xml_path, html_path = generate_package_coverage(
            "CoverageTest";
            html_name = nothing,
            cobertura_name = nothing,
        )
        @test isfile(joinpath(coverage_dir, "lcov.info"))
        @test xml_path === nothing
        @test html_path === nothing
        @test all(!endswith(".html"), readdir(coverage_dir))
        @test all(!endswith(".xml"), readdir(coverage_dir))

        # We now test extracting the coverage directly from the lcov.info file
        generate_package_coverage(
            "CoverageTest";
            use_existing_lcov = true,
        )
        @test isfile(joinpath(coverage_dir, "cobertura-coverage.xml"))
        @test isfile(joinpath(coverage_dir, "index.html"))

        clean_coverage(coverage_dir)
        @test !isdir(coverage_dir)
        cov, xml_path, html_path = generate_package_coverage(
            "CoverageTest";
            html_name = "magic.html",
            cobertura_name = nothing,
        )
        @test isfile(joinpath(coverage_dir, "lcov.info"))
        @test xml_path === joinpath(coverage_dir, "cobertura-coverage.xml")
        @test html_path === joinpath(coverage_dir, "magic.html")
        @test isfile(xml_path)
        @test isfile(html_path)
    finally
        Pkg.activate(current_proj)
    end
end

@testitem "julia_args reaches the test subprocess" begin
    import Pkg
    # `julia_args` must be forwarded to the julia process that `Pkg.test` spawns, so that
    # flags like `--heap-size-hint` actually take effect (the JULIA_HEAP_SIZE_HINT env var
    # is ignored; only the CLI flag sets Base.JLOptions().heap_size_hint).
    CoverageTest_dir = joinpath(@__DIR__, "CoverageTest")
    hint_file = tempname()
    current_proj = dirname(Base.active_project())
    Pkg.activate(CoverageTest_dir)
    try
        generate_package_coverage(
            "CoverageTest";
            test_args = [hint_file],          # fixture writes heap_size_hint here
            julia_args = ["--heap-size-hint=2G"],
            html_name = nothing,
            cobertura_name = nothing,
            print_to_stdout = false,
        )
        @test isfile(hint_file)
        @test parse(Int, read(hint_file, String)) == 2 * 2^30  # 2 GiB = 2147483648
    finally
        Pkg.activate(current_proj)
        rm(hint_file; force = true)
    end
end

@testitem "EXTENDEDLOCALCOVERAGE_HEAP_SIZE_HINT env var sets test heap hint" begin
    import Pkg
    # CI can set the test-process heap-size hint via an env var, without touching the call site.
    CoverageTest_dir = joinpath(@__DIR__, "CoverageTest")
    hint_file = tempname()
    current_proj = dirname(Base.active_project())
    Pkg.activate(CoverageTest_dir)
    try
        withenv("EXTENDEDLOCALCOVERAGE_HEAP_SIZE_HINT" => "2G") do
            generate_package_coverage(
                "CoverageTest";
                test_args = [hint_file],   # note: no julia_args passed; the env var must supply the flag
                html_name = nothing,
                cobertura_name = nothing,
                print_to_stdout = false,
            )
        end
        @test parse(Int, read(hint_file, String)) == 2 * 2^30  # 2 GiB = 2147483648
    finally
        Pkg.activate(current_proj)
        rm(hint_file; force = true)
    end
end

@testitem "explicit julia_args --heap-size-hint overrides env var" begin
    import Pkg
    # When both EXTENDEDLOCALCOVERAGE_HEAP_SIZE_HINT and an explicit --heap-size-hint in
    # julia_args are given, the explicit one must win (julia uses the last occurrence).
    CoverageTest_dir = joinpath(@__DIR__, "CoverageTest")
    hint_file = tempname()
    current_proj = dirname(Base.active_project())
    Pkg.activate(CoverageTest_dir)
    try
        withenv("EXTENDEDLOCALCOVERAGE_HEAP_SIZE_HINT" => "2G") do
            generate_package_coverage(
                "CoverageTest";
                test_args = [hint_file],
                julia_args = ["--heap-size-hint=4G"],
                html_name = nothing,
                cobertura_name = nothing,
                print_to_stdout = false,
            )
        end
        @test parse(Int, read(hint_file, String)) == 4 * 2^30  # explicit 4 GiB wins over env 2 GiB
    finally
        Pkg.activate(current_proj)
        rm(hint_file; force = true)
    end
end

@testitem "generate_package_coverage with no pkg arg uses the active project" begin
    import Pkg
    # Exercises the pkg=nothing path: pkgdir(nothing) -> active project, and Pkg.test by the
    # active project's own name (no isnothing(pkg) branch).
    CoverageTest_dir = joinpath(@__DIR__, "CoverageTest")
    current_proj = dirname(Base.active_project())
    Pkg.activate(CoverageTest_dir)
    try
        cov, xml, html = generate_package_coverage(; print_to_stdout = false)
        @test isfile(xml)
        @test isfile(html)
        rm(dirname(xml); recursive = true, force = true)
    finally
        Pkg.activate(current_proj)
    end
end

@testitem "highlighted_lines CRLF + multibyte" begin
    # Regression: CRLF line endings with a multibyte char (e.g. π) right before
    # the \r used to throw StringIndexError because the old code stripped the \r
    # with byte arithmetic (line[1:end-1]) instead of a char-safe chop.
    # On Julia 1.12+ JuliaSyntaxHighlighting is preloaded, so its extension is
    # active and ExtendedLocalCoverage.highlighted_lines is defined (same
    # assumption as the "html defaults functions" testitem below).
    @static if VERSION >= v"1.12"
        @assert ExtendedLocalCoverage.JuliaSyntaxHighlightingLoaded[] "JuliaSyntaxHighlighting extension not loaded"
        lines = ExtendedLocalCoverage.highlighted_lines(IOBuffer("x = 2π\r\nb = 1\r\n"))
        @test String(lines[1]) == "x = 2π"  # no trailing \r, no StringIndexError
        @test String(lines[2]) == "b = 1"
    end
end

@testitem "html defaults functions" begin
    using ExtendedLocalCoverage: default_lines_function, default_html_function

    lines_function = default_lines_function()
    html_function = default_html_function(lines_function)
    @static if VERSION >= v"1.12"
        @test lines_function == ExtendedLocalCoverage.highlighted_lines
        @test html_function == ExtendedLocalCoverage.highlight_with_show
    else
        @test lines_function == ExtendedLocalCoverage.plain_lines
        @test html_function == String
    end
end