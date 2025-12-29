module JuliaSyntaxHighlightingExt
    using JuliaSyntaxHighlighting: JuliaSyntaxHighlighting, highlight
    using ExtendedLocalCoverage: ExtendedLocalCoverage, StyledStringsLoaded


    function ExtendedLocalCoverage.highlighted_lines(io::IO)
        highlighted = highlight(io)
        map(eachsplit(highlighted, '\n')) do line
            endswith(line, '\r') ? line[1:end-1] : line # Deal with Windows line endings
        end
    end

    function __init__()
        # We set this flag to true to indicate that tye JuliaSyntaxHighlighting extension has been loaded
        ExtendedLocalCoverage.JuliaSyntaxHighlightingLoaded[] = true
    end
end