struct Metadata
    source::LineNumberNode
end

struct Note
    variables::NamedTuple
    metadata::Metadata
end

Base.pairs(note::Note) = getfield(note, :variables)
Metadata(note::Note) = getfield(note, :metadata)

Base.propertynames(note::Note) = propertynames(pairs(note))
Base.getproperty(note::Note, name::Symbol) = pairs(note)[name]

const NOTES = Note[]

function _record_note(source::LineNumberNode; variables...)
    @nospecialize variables
    push!(NOTES, Note((; variables...), Metadata(source)))
end

macro note(variables...)
    quote
        $_record_note($(QuoteNode(__source__)); $(variables...))
        nothing
    end |> esc
end
