using LocalCoverage: PackageCoverage, format_line
using PrettyTables: PrettyTables, pretty_table

"""
    WrappedPackageCoverage(summary::PackageCoverage)

Structure wrapping the `PackageCoverage` struct to add a custom `show` method for fixing PrettyTables issues until https://github.com/JuliaCI/LocalCoverage.jl/pull/68 is merged.
"""
struct WrappedPackageCoverage
    summary::PackageCoverage
end

function Base.getproperty(wrapped::WrappedPackageCoverage, s::Symbol)
    summary = getfield(wrapped, :summary)
    if s == :summary
        return summary
    else
        return getfield(summary, s)
    end
end

function Base.show(io::IO, wrapped::WrappedPackageCoverage)
    (; summary) = wrapped
    (; files, package_dir) = summary
    row_data = map(format_line, files)
    push!(row_data, format_line(summary))
    row_coverage = map(x -> x.coverage_percentage, row_data)
    rows = map(row_data) do row
        (; name, total, hit, missed, coverage_percentage, gaps) = row
        percentage = isnan(coverage_percentage) ? "-" : "$(round(Int, coverage_percentage))%"
        (; name, total, hit, missed, percentage, gaps)
    end
    header = ["Filename", "Lines", "Hit", "Miss", "%"]
    percentage_column = length(header)
    alignment = [:l, :r, :r, :r, :r]
    columns_width = fill(-1, 5) # We need strictly negative number to autosize in PrettyTables 3.0, but this also works in v2
    if get(io, :print_gaps, false)
        push!(header, "Gaps")
        push!(alignment, :l)
        display_cols = last(get(io, :displaysize, 100))
        push!(columns_width, display_cols - 45)
    else
        rows = map(row -> Base.structdiff(row, NamedTuple{(:gaps,)}), rows)
    end
    # PrettyTables 3.0 changed Highlighter to TextHighlighter, which up to currently published version (v3.10) does not provide the kwargs constructor (despite having it documented). We create here a patch to handle both cases
    Highlighter(f; kwargs...) = @static if pkgversion(PrettyTables) < v"3.0.0"
        PrettyTables.Highlighter(f; kwargs...)
    else
        PrettyTables.TextHighlighter(f, PrettyTables.Crayon(;kwargs...))
    end

    highlighters = (
        Highlighter(
            (data, i, j) -> j == percentage_column && row_coverage[i] <= 50,
            bold = true,
            foreground = :red,
        ),
        Highlighter((data, i, j) -> j == percentage_column && row_coverage[i] <= 70,
                    foreground = :yellow),
        Highlighter((data, i, j) -> j == percentage_column && row_coverage[i] >= 90,
                    foreground = :green),
    )

    # Kwargs of `pretty_table` itself also changed in PrettyTables 3.0, so we have to branch here as well
    @static if pkgversion(PrettyTables) < v"3.0.0"
        pretty_table(
            io,
            rows;
            title = "Coverage of $(package_dir)",
            header,
            alignment,
            crop = :none,
            linebreaks = true,
            columns_width,
            autowrap = true,
            highlighters,
            body_hlines = [length(rows) - 1],
        )
    else
        pretty_table(
            io,
            rows;
            title = "Coverage of $(package_dir)",
            column_labels = [header],
            alignment,
            # The crop kwarg is not present anymore, split into the next two ones
            fit_table_in_display_horizontally = false,
            fit_table_in_display_vertically = false,
            line_breaks = true,
            fixed_data_column_widths = columns_width,
            auto_wrap = true,
            highlighters = collect(highlighters), # v3 expects a vector instead of a Tuple
            table_format = PrettyTables.TextTableFormat(;
                horizontal_lines_at_data_rows = [length(rows) - 1],
            ),
        )
    end
end