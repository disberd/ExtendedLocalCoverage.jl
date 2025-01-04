module CoverageTest

export hello, foo, bar

hello() = "Hello"

include("foo.jl")
include("exclude_bar.jl")

end # module CoverageTest
