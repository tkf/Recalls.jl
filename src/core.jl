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

# TODO: lock-free
mutable struct Swappable{T,Lock}
    value::T
    lock::Lock
end

Swappable{T,L}(value) where {T,L} = Swappable{T,L}(value, L())

swap!(x::Swappable{T}, value::T) where {T} = something(swapif!(_ -> true, x, value))
function swapif!(f, x::Swappable{T}, value::T) where {T}
    lock(x.lock) do
        old = x.value
        if f(old)
            x.value = value
            return Some(old)
        else
            return nothing
        end
    end
end

function locked(f::F, x::Swappable) where {F}
    lock(x.lock) do
        f(x.value)
    end
end

const DEFAULT_SIZE = 256

const SwappableVector{T,L} = Swappable{Vector{T},L}
SwappableVector{T,L}() where {T,L} =
    SwappableVector{T,L}(empty!(Vector{T}(undef, DEFAULT_SIZE)))

const DefaultSwappableVector{T} = SwappableVector{T,Threads.SpinLock}

struct GlobalRecord{T} <: AbstractVector{T}
    sinks::Vector{DefaultSwappableVector{T}}
    reserves::Vector{Vector{T}}
    tmp::Vector{Vector{T}}
    buffer::Vector{T}
end

function GlobalRecord{T}() where {T}
    sinks = [DefaultSwappableVector{T}() for _ in 1:Threads.nthreads()]
    reserves = [empty!(Vector{T}(undef, DEFAULT_SIZE)) for _ in 1:Threads.nthreads()]
    tmp = empty!(Vector{Vector{T}}(undef, Threads.nthreads()))
    buffer = T[]
    return GlobalRecord{T}(sinks, reserves, tmp, buffer)
end

function init!(gr::GlobalRecord{T}) where {T}
    new = GlobalRecord{T}()
    append!(empty!(gr.sinks), new.sinks)
    append!(empty!(gr.reserves), new.reserves)
    append!(empty!(gr.tmp), new.tmp)
    empty!(gr.buffer)
    return gr
end

function maintain!(gr::GlobalRecord)
    need_merge = false
    for i in eachindex(gr.sinks, gr.reserves)
        result = swapif!(!isempty, gr.sinks[i], gr.reserves[i])
        if result isa Some
            old = gr.reserves[i] = something(result)
            push!(gr.tmp, old)
            need_merge = true
        end
    end
    if need_merge
        foldl(append!, gr.tmp; init = gr.buffer)
        foreach(empty!, gr.tmp)
        empty!(gr.tmp)
    end
end

function Base.empty!(gr::GlobalRecord)
    empty!(gr.buffer)
    for i in eachindex(gr.sinks, gr.reserves)
        gr.reserves[i] = empty!(swap!(gr.sinks[i], gr.reserves[i]))
    end
    return gr
end

function Base.size(gr::GlobalRecord)
    maintain!(gr)
    return size(gr.buffer)
end

function Base.getindex(gr::GlobalRecord, i::Int)
    @boundscheck checkbounds(gr, i)
    return gr.buffer[i]
end

function Base.put!(gr::GlobalRecord{T}, v::T) where {T}
    locked(gr.sinks[Threads.nthreads()]) do sink
        push!(sink, v)
    end
end
