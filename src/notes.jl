struct Note <: Object
    variables::NamedTuple
    metadata::Metadata
end

Base.NamedTuple(note::Note) = getfield(note, :variables)
Metadata(note::Note) = getfield(note, :metadata)

Base.propertynames(note::Note) = propertynames(NamedTuple(note))
Base.getproperty(note::Note, name::Symbol) = NamedTuple(note)[name]

"""
    Recalls.NOTES

This is a vector of notes created by `@note`.
"""
const NOTES = GlobalRecord{Note}()

function _record_note(metadata; variables...)
    @nospecialize variables
    put!(NOTES, Note((; variables...), metadata))
end

raw"""
    @note var₁ var₂ … varₙ

Record variables `varᵢ`.

Each `varᵢ` can take the following form:

1. a symbol prefixed by `$` (e.g., `$x`)
2. an assignment with the right hand side prefixed by `$` (e.g., `lhs = $rhs`)
3. a symbol (e.g., `x`)
4. an assignment (e.g., `lhs = rhs`)

Expressions prefixed by `$` will be `deepcopy`ed.
"""
macro note(variables...)
    metadata = metadata_expr(__source__, __module__)
    kwargs = map(variables) do v
        if v isa Symbol
            Expr(:kw, v, v)
        elseif Meta.isexpr(v, :$, 1) && v.args[1] isa Symbol
            Expr(:kw, v.args[1], :($deepcopy($(v.args[1]))))
        elseif (
                (Meta.isexpr(v, :(=), 2) || Meta.isexpr(v, :kw, 2)) &&
                Meta.isexpr(v.args[2], :$, 1)
            )
            Expr(:kw, v.args[1], :($deepcopy($(v.args[2].args[1]))))
        else
            v
        end
    end
    quote
        $_record_note($metadata; $(kwargs...))
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
