"""
Cobertura XML parser for coverage reports.
"""

using EzXML

"""
    LineData

Represents coverage data for a single line.
"""
struct LineData
    number::Int
    hits::Int
    branch::Bool
end

"""
    FileData

Represents coverage data for a single file.
"""
struct FileData
    filename::String
    line_rate::Float64
    lines::Vector{LineData}
end

"""
    CoverageData

Represents parsed coverage data from a Cobertura XML file.
"""
struct CoverageData
    timestamp::Int64
    line_rate::Float64
    lines_covered::Int
    lines_valid::Int
    files::Vector{FileData}
end

"""
    parse_cobertura(xml_file::String) -> CoverageData

Parse a Cobertura XML file and return structured coverage data.
"""
function parse_cobertura(xml_file::String)
    doc = readxml(xml_file)
    root = doc.root
    
    # Parse root attributes
    timestamp = parse(Int64, root["timestamp"])
    line_rate = parse(Float64, root["line-rate"])
    lines_covered = parse(Int, root["lines-covered"])
    lines_valid = parse(Int, root["lines-valid"])
    
    # Parse packages and files
    files = FileData[]
    
    for package in findall("//package", root)
        for class_elem in findall(".//class", package)
            filename = class_elem["filename"]
            class_line_rate = parse(Float64, class_elem["line-rate"])
            
            # Parse lines
            lines = LineData[]
            for line_elem in findall(".//line", class_elem)
                line_num = parse(Int, line_elem["number"])
                hits = parse(Int, line_elem["hits"])
                branch = line_elem["branch"] == "true"
                push!(lines, LineData(line_num, hits, branch))
            end
            
            push!(files, FileData(filename, class_line_rate, lines))
        end
    end
    
    return CoverageData(timestamp, line_rate, lines_covered, lines_valid, files)
end

"""
    calculate_file_stats(file::FileData) -> NamedTuple

Calculate statistics for a file: total lines, covered lines, missed lines, and missing ranges.
"""
function calculate_file_stats(file::FileData)
    total_lines = length(file.lines)
    covered_lines = count(line -> line.hits > 0, file.lines)
    missed_lines = total_lines - covered_lines
    coverage_pct = total_lines > 0 ? (covered_lines / total_lines) * 100 : 0.0
    
    # Find missing line ranges
    missing_ranges = String[]
    if missed_lines > 0
        sorted_missing = sort([line.number for line in file.lines if line.hits == 0])
        
        if !isempty(sorted_missing)
            range_start = sorted_missing[1]
            range_end = sorted_missing[1]
            
            for i in 2:length(sorted_missing)
                if sorted_missing[i] == range_end + 1
                    range_end = sorted_missing[i]
                else
                    push!(missing_ranges, range_start == range_end ? 
                          string(range_start) : 
                          string(range_start, "-", range_end))
                    range_start = sorted_missing[i]
                    range_end = sorted_missing[i]
                end
            end
            
            # Add the last range
            push!(missing_ranges, range_start == range_end ? 
                  string(range_start) : 
                  string(range_start, "-", range_end))
        end
    end
    
    missing_str = isempty(missing_ranges) ? "" : join(missing_ranges, ", ")
    
    return (
        total=total_lines,
        covered=covered_lines,
        missed=missed_lines,
        coverage=coverage_pct,
        missing=missing_str
    )
end

"""
    read_source_file(filepath::String, pkg_dir::String) -> Vector{String}

Read source file lines for display in the coverage report.
Returns empty vector if file cannot be read.
"""
function read_source_file(filepath::String, pkg_dir::String)
    # Try to construct the full path
    full_path = joinpath(pkg_dir, filepath)
    
    # Handle Windows backslashes
    full_path = replace(full_path, "\\" => "/")
    full_path = replace(full_path, "//" => "/")
    
    if !isfile(full_path)
        # Try without pkg_dir
        full_path = filepath
        if !isfile(full_path)
            return String[]
        end
    end
    
    try
        return readlines(full_path)
    catch e
        @warn "Could not read source file: $full_path" exception=e
        return String[]
    end
end
