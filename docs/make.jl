using ExtendedLocalCoverage
using Documenter

DocMeta.setdocmeta!(ExtendedLocalCoverage, :DocTestSetup, :(using ExtendedLocalCoverage); recursive = true)

const page_rename = Dict("developer.md" => "Developer docs") # Without the numbers
const numbered_pages = [
    file for file in readdir(joinpath(@__DIR__, "src")) if
    file != "index.md" && splitext(file)[2] == ".md"
]

makedocs(;
    modules = [ExtendedLocalCoverage],
    authors = "Alberto Mengali <a.mengali@gmail.com>",
    repo = "https://github.com/disberd/ExtendedLocalCoverage.jl/blob/{commit}{path}#{line}",
    sitename = "ExtendedLocalCoverage.jl",
    format = Documenter.HTML(; canonical = "https://disberd.github.io/ExtendedLocalCoverage.jl"),
    pages = ["index.md"; numbered_pages],
)

deploydocs(; repo = "github.com/disberd/ExtendedLocalCoverage.jl")
