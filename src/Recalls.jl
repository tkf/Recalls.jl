module Recalls

export @note, @recall, recall

using .Meta: isexpr
using Dates: Second, now
using ExprTools: combinedef, splitdef
using Requires: @require

include("core.jl")
include("metadata.jl")
include("calls.jl")
include("notes.jl")

# `no_juliainterpreter.jl` includes `juliainterpreter.jl` with a fake
# `Juliainterpreter` module for defining `_call` without a breakpoint.
# `_call` will be re-defined at run-time after `JuliaInterpreter` is
# loaded
include("no_juliainterpreter.jl")

function __init__()
    init!(NOTES)
    @require JuliaInterpreter = "aa1ae85d-cabe-5617-a682-6adf51b2e16a" include("juliainterpreter.jl")
end

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end Recalls

end
