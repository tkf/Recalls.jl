struct Metadata <: Object
    source::LineNumberNode
    _module::Module
    location::UUID
    threadid::Int
    timestamp::typeof(time())
end

Metadata(source, _module, location = UUID(0)) =
    Metadata(source, _module, location, Threads.threadid(), time())

metadata_expr(__source__, __module__) =
    :($Metadata($(QuoteNode(__source__)), $(QuoteNode(__module__)), $(QuoteNode(uuid4()))))

function _summary(io, metadata::Metadata)
    dt = roughly_as_datetime(metadata.timestamp)
    file = string(metadata.source.file)
    line = metadata.source.line
    print(io, metadata._module, " ", file, ":", line, " @", dt)
end

function Base.show(io::IO, ::MIME"text/plain", metadata::Metadata)
    dt = roughly_as_datetime(metadata.timestamp)
    file = string(metadata.source.file)
    line = metadata.source.line
    print(io, "<")
    _summary(io, metadata)
    print(io, ">")
end

roughly_as_datetime(t::Real) = now() + Second(floor(Int, time() - t))
