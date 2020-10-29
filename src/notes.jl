struct Note
    variables::NamedTuple
    metadata::Metadata
end

Base.pairs(note::Note) = getfield(note, :variables)
Metadata(note::Note) = getfield(note, :metadata)

Base.propertynames(note::Note) = propertynames(pairs(note))
Base.getproperty(note::Note, name::Symbol) = pairs(note)[name]

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
