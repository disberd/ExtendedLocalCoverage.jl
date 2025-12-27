@testitem "ExtendedLocalCoverage.jl" begin
    using ExtendedLocalCoverage: PackageCoverage, WrappedPackageCoverage
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

        # getproperty test
        @test cov isa WrappedPackageCoverage
        @test cov.summary isa PackageCoverage
        @test cov.lines_hit isa Int
    finally
        Pkg.activate(current_proj)
    end
end