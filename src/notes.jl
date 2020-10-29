struct Note <: Object
    variables::NamedTuple
    metadata::Metadata
end

Base.NamedTuple(note::Note) = getfield(note, :variables)
Metadata(note::Note) = getfield(note, :metadata)

Base.propertynames(note::Note) = propertynames(NamedTuple(note))
Base.getproperty(note::Note, name::Symbol) = NamedTuple(note)[name]

const NOTES = Note[]

function _record_note(metadata; variables...)
    @nospecialize variables
    push!(NOTES, Note((; variables...), metadata))
end

macro note(variables...)
    metadata = metadata_expr(__source__, __module__)
    quote
        $_record_note($metadata; $(variables...))
        nothing
    end |> esc
end

function Base.summary(io::IO, note::Note)
    print(io, "@note with ", length(NamedTuple(note)), " variable(s) for ")
    _summary(io, Metadata(note))
end

function Base.show(io::IO, ::MIME"text/plain", note::Note)
    summary(io, note)
    get(io, :compact, false) && return
    for (k, v) in pairs(NamedTuple(note))
        println(io)
        print(io, k, " = ")
        show(io, v)
    end
end
