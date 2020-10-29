abstract type Object end

# Avoid accidental infinite recursion:
Base.show(io::IO, ::MIME"text/plain", x::Object) = invoke(show, Tuple{IO,Any}, io, x)

function Base.show(io::IO, x::Object)
    if get(io, :limit, false)
        # Support `Vector{typeof(x)}` etc. with saner default:
        show(IOContext(io, :compact => true), MIME"text/plain"(), x)
        return
    end
    invoke(show, Tuple{IO,Any}, io, x)
    return
end
