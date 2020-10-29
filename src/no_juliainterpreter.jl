function _call end

module NoJuliaInterpreter

module JuliaInterpreter
macro bp() end
end

import ..Recalls: _call
include("juliainterpreter.jl")

end
