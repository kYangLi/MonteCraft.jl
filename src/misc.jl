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
    norm_x = norm(x)
    if norm_x < eps()
        return x
    end
    return x / norm_x
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