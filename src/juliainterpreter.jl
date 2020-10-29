function _call(re)
    # Make it dumb so that it's easier in debugger:
    f = re.f
    args = re.args
    kwargs = re.kwargs
    JuliaInterpreter.@bp
    # NOTE: Hit `s` (maybe twice) to step into the recorded function, if you are in a debugger.
    return f(args...; kwargs...)
end
