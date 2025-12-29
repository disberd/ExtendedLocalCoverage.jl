module StyledStringsExt
    using StyledStrings: StyledStrings, AnnotatedString
    using ExtendedLocalCoverage: ExtendedLocalCoverage, StyledStringsLoaded

const VALID_TYPE = Union{AnnotatedString, SubString{<:AnnotatedString}}

function ExtendedLocalCoverage.highlight_with_show(line::VALID_TYPE)
    io = IOBuffer()
    show(io, MIME"text/html"(), line)
    return String(take!(io))
end

function ExtendedLocalCoverage.highlight_with_classes(highlighted::VALID_TYPE)
    result = IOBuffer()
    try
        for (content, annots) in Base.eachregion(highlighted)
            print(result, "<span")
            if !isempty(annots)
                print(result, " class=\"")
                print(result, join(map(a -> a.value, annots), " "))
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

function __init__()
    # We set this flag to true to indicate that tye StyledStrings extension has been loaded
    StyledStringsLoaded[] = true
end

end