@testset "ExtendedLocalCoverage.jl" begin
    xml, html = generate_extended_coverage("Example")
    @test dirname(xml) |> endswith("coverage")
    @test isfile(xml)
    @test isfile(html)
end
