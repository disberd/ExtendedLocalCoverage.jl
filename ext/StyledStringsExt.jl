module StyledStringsExt
    using StyledStrings: StyledStrings, AnnotatedString
    using ExtendedLocalCoverage: ExtendedLocalCoverage, StyledStringsLoaded, SafeString

const VALID_TYPE = Union{AnnotatedString, SubString{<:AnnotatedString}}

function ExtendedLocalCoverage.highlight_with_show(line::VALID_TYPE)
    io = IOBuffer()
    show(io, MIME"text/html"(), line)
    return String(take!(io)) |> SafeString
end

function __init__()
    # We set this flag to true to indicate that the StyledStrings extension has been loaded
    StyledStringsLoaded[] = true
end

end