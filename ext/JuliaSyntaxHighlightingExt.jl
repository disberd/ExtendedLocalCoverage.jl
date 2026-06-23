module JuliaSyntaxHighlightingExt
    using JuliaSyntaxHighlighting: JuliaSyntaxHighlighting, highlight
    using ExtendedLocalCoverage: ExtendedLocalCoverage


    function ExtendedLocalCoverage.highlighted_lines(io::IO)
        highlighted = highlight(io)
        map(eachsplit(highlighted, '\n')) do line
            endswith(line, '\r') ? chop(line) : line # Deal with Windows line endings (chop is char-safe, unlike byte indexing)
        end
    end

    function __init__()
        # We set this flag to true to indicate that tye JuliaSyntaxHighlighting extension has been loaded
        ExtendedLocalCoverage.JuliaSyntaxHighlightingLoaded[] = true
    end
end