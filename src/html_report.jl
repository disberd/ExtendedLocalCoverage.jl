"""
HTML report generator using HypertextTemplates.jl for coverage reports.
"""

using HypertextTemplates
using HypertextTemplates.Elements
using Dates
using JuliaSyntaxHighlighting: highlight

include("cobertura_parser.jl")

"""
    modern_css_styles() -> String

Return modern CSS styling for the coverage report.
Fully static, no runtime JavaScript required.
"""
function modern_css_styles()
    return read(joinpath(@__DIR__, "style.css"), String)
end

function highlight_to_html(highlighted::Union{SubString{<:AnnotatedString}, AnnotatedString})
    result = IOBuffer()
    try
        for (content, annots) in Base.eachregion(highlighted)
            print(result, "<span")
            if !isempty(annots)
                print(result, " class=\"")
                print(result, join(Base.map(a -> a.value, annots), " "))
                print(result, "\"")
            end
            print(result, ">")
            print(result, content)
            print(result, "</span>")
        end
    catch e
        # If highlighting fails, return escaped plain text
        return String(highlighted)
    end
    
    return String(take!(result))
end

"""
    coverage_badge_class(coverage::Float64) -> String

Return CSS class for coverage badge based on coverage percentage.
"""
function coverage_badge_class(coverage::Float64)
    if coverage >= 80.0
        return "coverage-excellent"
    elseif coverage >= 60.0
        return "coverage-good"
    else
        return "coverage-poor"
    end
end

# Component that renders a file summary table with links to detailed sections
@component function file_summary_table_component(; data::CoverageData)
    @div {class = "summary-table-section"} begin
        @h2 "📋 Files Overview"
        @table {class = "file-summary-table"} begin
            @thead begin
                @tr begin
                    @th "File"
                    @th {class = "stats-cell"} "Total Lines"
                    @th {class = "stats-cell"} "Covered"
                    @th {class = "stats-cell"} "Missed"
                    @th {class = "stats-cell"} "Coverage"
                    @th "Missing Lines"
                end
            end
            @tbody begin
                for (idx, file) in enumerate(data.files)
                    stats = calculate_file_stats(file)
                    badge_class = coverage_badge_class(stats.coverage)
                    file_anchor = "file-$idx"
                    
                    @tr begin
                        @td begin
                            @a {class = "file-link", href = "#$file_anchor"} $(file.filename)
                        end
                        @td {class = "stats-cell"} $(stats.total)
                        @td {class = "stats-cell"} $(stats.covered)
                        @td {class = "stats-cell"} $(stats.missed)
                        @td {class = "stats-cell"} begin
                            @span {class = "coverage-badge $badge_class"} "$(round(stats.coverage, digits=2))%"
                        end
                        @td {class = "missing-cell"} $(isempty(stats.missing) ? "—" : stats.missing)
                    end
                end
            end
        end
    end
end
@deftag macro file_summary_table_component end

# Component that renders the summary metrics section
@component function summary_section_component(; data::CoverageData)
    coverage_pct = data.line_rate * 100
    
    @div {class = "summary"} begin
        @div {class = "metric"} begin
            @div {class = "metric-label"} "Total Coverage"
            @div {class = "metric-value"} "$(round(coverage_pct, digits=2))%"
            @div {class = "metric-subtext"} "$(data.lines_covered) of $(data.lines_valid) lines"
        end
        @div {class = "metric"} begin
            @div {class = "metric-label"} "Lines Covered"
            @div {class = "metric-value"} "$(data.lines_covered)"
            @div {class = "metric-subtext"} "executable lines"
        end
        @div {class = "metric"} begin
            @div {class = "metric-label"} "Lines Uncovered"
            @div {class = "metric-value"} "$(data.lines_valid - data.lines_covered)"
            @div {class = "metric-subtext"} "need testing"
        end
        @div {class = "metric"} begin
            @div {class = "metric-label"} "Files"
            @div {class = "metric-value"} "$(length(data.files))"
            @div {class = "metric-subtext"} "in project"
        end
    end
end
@deftag macro summary_section_component end

# Component that renders a single line of source code with coverage highlighting
@component function code_line_component(; line_num::Int, content::AbstractString, hits::Union{Int,Nothing})
    line_class = if isnothing(hits)
        "code-line line-neutral"
    elseif hits > 0
        "code-line line-covered"
    else
        "code-line line-uncovered"
    end
    
    # Apply syntax highlighting
    highlighted_content = let
        # io = IOBuffer()
        # show(io, MIME"text/html"(), content)
        # String(take!(io)) |> HypertextTemplates.SafeString
        highlight_to_html(content) |> HypertextTemplates.SafeString
    end
    
    @div {class = line_class} begin
        @div {class = "line-number"} $line_num
        @div {class = "line-content"} @text highlighted_content
    end
end
@deftag macro code_line_component end

# Component that renders a single file card with coverage information and source code
@component function file_card_component(; file::FileData, pkg_dir::String, file_index::Int)
    stats = calculate_file_stats(file)
    source_lines = read_source_file(file.filename, pkg_dir)
    
    # Create a map of line number -> hits
    line_hits = Dict(line.number => line.hits for line in file.lines)
    
    badge_class = coverage_badge_class(stats.coverage)
    file_anchor = "file-$file_index"
    
    @div {class = "file-card", id = file_anchor} begin
        @div {class = "file-header"} begin
            @div {class = "file-name"} $(file.filename)
            @div {class = "file-stats"} begin
                @span {class = "stat"} begin
                    @span {class = "coverage-badge $badge_class"} "$(round(stats.coverage, digits=2))%"
                end
                @span {class = "stat"} begin
                    @span "📊 $(stats.covered)/$(stats.total) lines"
                end
                @span {class = "stat"} begin
                    @span "❌ $(stats.missed) missed"
                end
            end
        end
        
        # Source code section
        if !isempty(source_lines)
            @div {class = "source-code"} begin
                for (i, line) in enumerate(source_lines)
                    @code_line_component {
                        line_num = i,
                        content = line,
                        hits = get(line_hits, i, nothing)
                    }
                end
            end
        else
            @div {class = "source-code"} begin
                @div {style = "padding: 20px; text-align: center; color: #666;"} begin
                    "Source code not available"
                end
            end
        end
        
        # Missing lines section
        if !isempty(stats.missing)
            @div {class = "missing-lines"} begin
                @strong "Uncovered Lines: "
                @text stats.missing
            end
        end
    end
end
@deftag macro file_card_component end

"""
    generate_native_html_report(cobertura_file::String, output_file::String;
                                 title::String="Coverage Report",
                                 pkg_dir::String=dirname(cobertura_file))

Generate a modern, static HTML coverage report from a Cobertura XML file using HypertextTemplates.jl.

# Arguments
- `cobertura_file`: Path to the Cobertura XML file
- `output_file`: Path where the HTML report should be written
- `title`: Title for the HTML report (default: "Coverage Report")
- `pkg_dir`: Root directory of the package for resolving source file paths (default: directory of cobertura_file)

# Example
```julia
generate_native_html_report(
    "coverage/cobertura-coverage.xml",
    "coverage/report.html",
    title="MyPackage Coverage"
)
```
"""
function generate_native_html_report(cobertura_file::String, output_file::String;
                                     title::String="Coverage Report",
                                     pkg_dir::String=dirname(cobertura_file))
    # Parse the Cobertura XML file
    data = parse_cobertura(cobertura_file)
    
    # Generate timestamp
    timestamp = Dates.format(Dates.unix2datetime(data.timestamp), "yyyy-mm-dd HH:MM:SS")
    
    # Build and render the HTML document
    function render_html(io)
        # We disable debug mode which is automatically enabled in HypertextTemplates.jl when Revise is loaded. This is a hack as mentioned in https://github.com/MichaelHatherly/HypertextTemplates.jl/issues/36#issuecomment-3004032438
        ctx = IOContext(io, HypertextTemplates._include_data_htloc() => false)
        @render ctx begin
            @html {lang = "en"} begin
                @head begin
                    @meta {charset = "UTF-8"}
                    @meta {name = "viewport", content = "width=device-width, initial-scale=1.0"}
                    @title $title
                    @style @text modern_css_styles()
                end
                @body begin
                    @div {class = "container"} begin
                        # Header
                        @header begin
                            @h1 $title
                            # @div {class = "subtitle"} begin
                            #     "Generated on "
                            #     @text timestamp
                            # end
                        end
                        
                        # Summary metrics
                        @summary_section_component {data = data}
                        
                        # File summary table
                        @file_summary_table_component {data = data}
                        
                        # File coverage details
                        @div {class = "files-section"} begin
                            @h2 "📁 File Coverage Details"
                            for (idx, file) in enumerate(data.files)
                                @file_card_component {file = file, pkg_dir = pkg_dir, file_index = idx}
                            end
                        end
                        
                        # Footer
                        @footer begin
                            "Generated by ExtendedLocalCoverage.jl using HypertextTemplates.jl"
                        end
                    end
                end
            end
        end
    end
    
    # Write to file
    open(output_file, "w") do io
        render_html(io)
    end
    
    @info "HTML coverage report generated: $output_file"
    return output_file
end

function highlighted_lines(io::IO)
    highlighted = highlight(io)
    Base.map(eachsplit(highlighted, '\n')) do line
        endswith(line, '\r') ? line[1:end-1] : line # Deal with Windows line endings
    end
end