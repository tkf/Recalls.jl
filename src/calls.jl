struct Record <: Object
    f::Any
    args::Any
    kwargs::Any
    metadata::Metadata
end

(re::Record)() = _call(re)

const HISTORY = Record[]

function _record(metadata, f, args...; kwargs...)
    @nospecialize
    push!(HISTORY, Record(f, args, kwargs, metadata))
    return
end

recorder(f, metadata) = function _recorder_(args...; kwargs...)
    push!(HISTORY, Record(f, args, kwargs, metadata))
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
    metadata = metadata_expr(__source__, __module__)
    if isexpr(ex, :call)
        return esc(Expr(ex.head, :($recorder($(ex.args[1]), $metadata)), ex.args[2:end]...))
    elseif (def = splitdef(ex)) !== nothing
        f = get(def, :name, nothing)
        f === nothing && error("Cannot record an anonymous function:\n", ex)
        args = def[:args]
        kwargs = map(as_kwarg, get(def, :kwargs, []))
        def[:body] = Expr(:block, quote
            $_record($metadata, $f, $(args...); $(kwargs...))
        end, def[:body])
        return esc(combinedef(def))
    end
    error("Not call or function definition:\n", ex)
end

function _summary(io, re::Record)
    print(io, "@recall ", re.f, "(")
    if get(io, :compact, false)
        if isempty(re.args)
            if !isempty(re.kwargs)
                k, v = first(re.kwargs)
                print(io, "; ", k, "=")
                print(io, v)
                print(io, ", ...")
            end
        elseif length(re.args) == 1
            print(io, re.args[1])
            if !isempty(re.kwargs)
                print(io, "; ...")
            end
        else
            print(io, re.args[1])
            print(io, ", ...")
        end
    else
        join(io, re.args, ", ")
        if !isempty(re.kwargs)
            isfirst = true
            for (k, v) in pairs(re.kwargs)
                if isfirst
                    print(io, "; ")
                    isfirst = true
                else
                    print(io, ", ")
                end
                print(io, k, "=", v)
            end
        end
    end
    print(io, ") at ")
    _summary(io, re.metadata)
end

function Base.show(io::IO, ::MIME"text/plain", re::Record)
    _summary(IOContext(io, :compact => true), re)
    get(io, :compact, false) && return
    if !isempty(re.args)
        println(io)
        print(io, length(re.args), " argument(s):")
        for (i, a) in enumerate(re.args)
            println(io)
            print(io, "  #", i, " = ")
            print(io, a)
        end
    end
    if !isempty(re.kwargs)
        println(io)
        print(io, length(re.kwargs), " keyword argument(s):")
        for (k, v) in pairs(re.kwargs)
            println(io)
            print(io, "  ", k, " = ")
            print(io, v)
        end
    end
end
