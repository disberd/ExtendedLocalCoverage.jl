"""
HTML report generator using HypertextTemplates.jl for coverage reports.
"""

using HypertextTemplates
using HypertextTemplates.Elements
using Dates


include("cobertura_parser.jl")

"""
    modern_css_styles() -> String

Return modern CSS styling for the coverage report.
Fully static, no runtime JavaScript required.
"""
function modern_css_styles()
    return """
    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }
    
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        line-height: 1.6;
        color: #333;
        background: #f5f7fa;
        padding: 20px;
    }
    
    .container {
        max-width: 1400px;
        margin: 0 auto;
        background: white;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        overflow: hidden;
    }
    
    header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 30px;
    }
    
    header h1 {
        font-size: 28px;
        margin-bottom: 8px;
    }
    
    header .subtitle {
        opacity: 0.9;
        font-size: 14px;
    }
    
    .summary {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 20px;
        padding: 30px;
        background: #fafbfc;
        border-bottom: 1px solid #e1e4e8;
    }
    
    .metric {
        background: white;
        padding: 20px;
        border-radius: 6px;
        border-left: 4px solid #667eea;
        box-shadow: 0 1px 3px rgba(0,0,0,0.08);
    }
    
    .metric-label {
        font-size: 12px;
        text-transform: uppercase;
        color: #666;
        font-weight: 600;
        margin-bottom: 8px;
        letter-spacing: 0.5px;
    }
    
    .metric-value {
        font-size: 32px;
        font-weight: bold;
        color: #333;
    }
    
    .metric-subtext {
        font-size: 13px;
        color: #666;
        margin-top: 4px;
    }
    
    .files-section {
        padding: 30px;
    }
    
    .files-section h2 {
        font-size: 20px;
        margin-bottom: 20px;
        color: #333;
    }
    
    .summary-table-section {
        padding: 30px;
        border-bottom: 1px solid #e1e4e8;
    }
    
    .summary-table-section h2 {
        font-size: 20px;
        margin-bottom: 20px;
        color: #333;
    }
    
    .file-summary-table {
        width: 100%;
        border-collapse: collapse;
        background: white;
        border-radius: 6px;
        overflow: hidden;
        box-shadow: 0 1px 3px rgba(0,0,0,0.08);
    }
    
    .file-summary-table thead {
        background: #fafbfc;
        border-bottom: 2px solid #e1e4e8;
    }
    
    .file-summary-table th {
        padding: 12px 16px;
        text-align: left;
        font-size: 12px;
        font-weight: 600;
        color: #666;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    
    .file-summary-table th:last-child {
        text-align: right;
    }
    
    .file-summary-table td {
        padding: 12px 16px;
        border-bottom: 1px solid #e1e4e8;
        font-size: 14px;
    }
    
    .file-summary-table tbody tr:hover {
        background: #f6f8fa;
    }
    
    .file-summary-table tbody tr:last-child td {
        border-bottom: none;
    }
    
    .file-summary-table .file-link {
        color: #0366d6;
        text-decoration: none;
        font-family: 'Consolas', 'Monaco', monospace;
        font-size: 13px;
    }
    
    .file-summary-table .file-link:hover {
        text-decoration: underline;
    }
    
    .file-summary-table .stats-cell {
        text-align: center;
        font-family: 'Consolas', 'Monaco', monospace;
    }
    
    .file-summary-table .missing-cell {
        font-family: 'Consolas', 'Monaco', monospace;
        font-size: 12px;
        color: #d73a49;
        max-width: 300px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }
    
    .file-card {
        background: white;
        border: 1px solid #e1e4e8;
        border-radius: 6px;
        margin-bottom: 20px;
        overflow: hidden;
        transition: box-shadow 0.2s;
    }
    
    .file-card:hover {
        box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    
    .file-header {
        padding: 16px 20px;
        background: #fafbfc;
        border-bottom: 1px solid #e1e4e8;
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: 10px;
    }
    
    .file-name {
        font-family: 'Consolas', 'Monaco', monospace;
        font-size: 14px;
        font-weight: 600;
        color: #333;
    }
    
    .file-stats {
        display: flex;
        gap: 20px;
        font-size: 13px;
    }
    
    .stat {
        display: flex;
        align-items: center;
        gap: 6px;
    }
    
    .coverage-badge {
        padding: 4px 12px;
        border-radius: 12px;
        font-weight: 600;
        font-size: 12px;
    }
    
    .coverage-excellent {
        background: #d4edda;
        color: #155724;
    }
    
    .coverage-good {
        background: #fff3cd;
        color: #856404;
    }
    
    .coverage-poor {
        background: #f8d7da;
        color: #721c24;
    }
    
    .source-code {
        max-height: 600px;
        overflow-y: auto;
        background: #f6f8fa;
    }
    
    .code-line {
        display: flex;
        font-family: 'Consolas', 'Monaco', monospace;
        font-size: 13px;
        line-height: 1.5;
        border-bottom: 1px solid #e1e4e8;
    }
    
    .code-line:last-child {
        border-bottom: none;
    }
    
    .line-number {
        min-width: 60px;
        padding: 4px 12px;
        text-align: right;
        color: #666;
        background: #fafbfc;
        border-right: 1px solid #e1e4e8;
        user-select: none;
    }
    
    .line-content {
        flex: 1;
        padding: 4px 12px;
        white-space: pre;
        overflow-x: auto;
    }
    
    .line-covered {
        background: #e6ffec;
        border-left: 3px solid #28a745;
    }
    
    .line-uncovered {
        background: #ffe6e6;
        border-left: 3px solid #dc3545;
    }
    
    .line-neutral {
        background: white;
    }
    
    /* Julia Syntax Highlighting */
    .jl-keyword { color: #d73a49; font-weight: 600; }
    .jl-string { color: #032f62; }
    .jl-comment { color: #6a737d; font-style: italic; }
    .jl-number { color: #005cc5; }
    .jl-operator { color: #d73a49; }
    .jl-function { color: #6f42c1; }
    .jl-type { color: #005cc5; font-weight: 600; }
    .jl-macro { color: #e36209; }
    .jl-symbol { color: #22863a; }
    
    .missing-lines {
        padding: 12px 20px;
        background: #fff5f5;
        border-top: 1px solid #e1e4e8;
        font-family: 'Consolas', 'Monaco', monospace;
        font-size: 12px;
        color: #d73a49;
    }
    
    .missing-lines strong {
        color: #721c24;
    }
    
    footer {
        padding: 20px 30px;
        background: #fafbfc;
        border-top: 1px solid #e1e4e8;
        text-align: center;
        color: #666;
        font-size: 13px;
    }
    
    @media (max-width: 768px) {
        .summary {
            grid-template-columns: 1fr;
        }
        
        .file-header {
            flex-direction: column;
            align-items: flex-start;
        }
    }
    """
end

"""
    highlight_julia_syntax(code::AbstractString) -> String

Apply Julia syntax highlighting to source code by wrapping tokens in HTML spans.
Returns HTML-safe string with syntax highlighting.
"""
function highlight_julia_syntax(code::AbstractString)
    # Escape HTML first
    code = replace(code, "&" => "&amp;")
    code = replace(code, "<" => "&lt;")
    code = replace(code, ">" => "&gt;")
    
    # Julia keywords
    keywords = r"\b(function|end|if|else|elseif|for|while|break|continue|return|try|catch|finally|do|begin|let|local|global|const|struct|mutable|abstract|primitive|type|module|baremodule|using|import|export|macro|quote|true|false|nothing)\b"
    code = replace(code, keywords => s"<span class='jl-keyword'>\g<0></span>")
    
    # Comments (must be before strings to handle # in strings correctly)
    code = replace(code, r"#[^\n]*" => s"<span class='jl-comment'>\g<0></span>")
    
    # Strings (triple-quoted and regular)
    code = replace(code, r"\"\"\"[\s\S]*?\"\"\"" => s"<span class='jl-string'>\g<0></span>")
    code = replace(code, r"\"(?:[^\"\\\n]|\\.)*\"" => s"<span class='jl-string'>\g<0></span>")
    
    # Macros
    code = replace(code, r"@\w+" => s"<span class='jl-macro'>\g<0></span>")
    
    # Numbers
    code = replace(code, r"\b\d+\.?\d*([eE][+-]?\d+)?\b" => s"<span class='jl-number'>\g<0></span>")
    
    # Symbols
    code = replace(code, r":\w+" => s"<span class='jl-symbol'>\g<0></span>")
    
    # Types (capitalized words, common pattern in Julia)
    code = replace(code, r"\b[A-Z]\w*\b" => s"<span class='jl-type'>\g<0></span>")
    
    return code
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
@component function code_line_component(; line_num::Int, content::String, hits::Union{Int,Nothing})
    line_class = if isnothing(hits)
        "code-line line-neutral"
    elseif hits > 0
        "code-line line-covered"
    else
        "code-line line-uncovered"
    end
    
    # Apply syntax highlighting
    highlighted_content = highlight_julia_syntax(content)
    
    @div {class = line_class} begin
        @div {class = "line-number"} $line_num
        @div {class = "line-content"} @text HypertextTemplates.SafeString(highlighted_content)
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
    html_content = @render begin
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
    
    # Write to file
    open(output_file, "w") do io
        println(io, "<!DOCTYPE html>")
        print(io, html_content)
    end
    
    @info "HTML coverage report generated: $output_file"
    return output_file
end