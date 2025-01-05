@testset "ExtendedLocalCoverage.jl" begin
    function clean_coverage()
        coverage_dir = joinpath(@__DIR__, "CoverageTest", "coverage")
        rm(coverage_dir, recursive = true, force = true)
    end
    cov, xml, html = generate_package_coverage("CoverageTest"; exclude = ["foo", r"bar"])
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

    clean_coverage()
end

