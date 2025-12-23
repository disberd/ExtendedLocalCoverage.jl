# Test the native HTML report generation

# First, let's test the parser and HTML generator
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

using ExtendedLocalCoverage

# Test with the existing cobertura file
cobertura_file = joinpath(@__DIR__, "..", "coverage", "cobertura-coverage.xml")
output_file = joinpath(@__DIR__, "..", "coverage", "native-report.html")
pkg_dir = joinpath(@__DIR__, "..")

println("Testing native HTML report generation...")
println("Input: $cobertura_file")
println("Output: $output_file")
println()

try
    generate_native_html_report(
        cobertura_file,
        output_file;
        title="ExtendedLocalCoverage Test Report",
        pkg_dir=pkg_dir
    )
    println("✓ Success! HTML report generated at: $output_file")
catch e
    println("✗ Error: $e")
    showerror(stdout, e, catch_backtrace())
end
