struct Record
    f::Any
    args::Any
    kwargs::Any
end

(re::Record)() = _call(re)

const HISTORY = Record[]

function _record(f, args...; kwargs...)
    @nospecialize
    push!(HISTORY, Record(f, args, kwargs))
    return
end

recorder(f) = function _recorder_(args...; kwargs...)
    push!(HISTORY, Record(f, args, kwargs))
    return f(args...; kwargs...)
end

"""
    recall()

Re-run the last call to function `f` instrumented by `@recall f(...)`.
"""
recall() =
    _call(HISTORY[end]) # NOTE: Hit `c` (continue) to jump to the point just before the actual call, if you are in a debugger.

#=
macro recall()
    :(recall())
end
=#

as_kwarg(x::Symbol) = x
as_kwarg(ex::Expr) =
    if isexpr(ex, :kw) || isexpr(ex, :(::))
        as_kwarg(ex.args[1])
    elseif isexpr(ex, :(...))
        ex
    else
        error("Unsupported keyword argument syntax: ", ex)
    end

"""
    @recall function f(...) ... end
    @recall f(...)

Record history of function calls.
"""
macro recall(ex)
    if isexpr(ex, :call)
        return esc(Expr(ex.head, :($recorder($(ex.args[1]))), ex.args[2:end]...))
    elseif (def = splitdef(ex)) !== nothing
        f = get(def, :name, nothing)
        f === nothing && error("Cannot record an anonymous function:\n", ex)
        args = def[:args]
        kwargs = map(as_kwarg, get(def, :kwargs, []))
        def[:body] = Expr(:block, quote
            $_record($f, $(args...); $(kwargs...))
        end, def[:body])
        return esc(combinedef(def))
    end
    error("Not call or function definition:\n", ex)
end
