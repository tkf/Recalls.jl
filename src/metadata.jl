struct Metadata
    source::LineNumberNode
    _module::Module
    timestamp::typeof(time())
end

Metadata(source, _module) = Metadata(source, _module, time())

metadata_expr(__source__, __module__) =
    :($Metadata($(QuoteNode(__source__)), $(QuoteNode(__module__))))
