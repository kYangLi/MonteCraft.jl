module MiscTools

using LinearAlgebra: norm

export vecvec2matrix, normalize, linear_sequence, log_sequence

"""
"""
function vecvec2matrix(vecvec::Vector)::Matrix
    return hcat(vecvec...)'
end


"""
"""
function normalize(x)
    return x / norm(x)
end


"""
"""
function linear_sequence(start, stop, step)
    return collect(range(start, stop; step=step))
end


"""
"""
function log_sequence(start, stop, step)
    return exp.(range(log(start), log(stop); step=log(step)))
end


end