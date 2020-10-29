module Recalls

export @note, @recall, recall

using .Meta: isexpr
using ExprTools: combinedef, splitdef
using Requires: @require

include("calls.jl")
include("no_juliainterpreter.jl")
include("notes.jl")

function __init__()
    @require JuliaInterpreter = "aa1ae85d-cabe-5617-a682-6adf51b2e16a" include("juliainterpreter.jl")
end

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end Recalls

end
