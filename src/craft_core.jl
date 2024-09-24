module CraftCore

using Random
using LinearAlgebra: dot
using ProgressBars

using ..MonteCraft

export evoluate_under_T, random_select_cell_without_dead, update_pattern


# Import the necessary
const NORM_NN = NEAREST_NEIGHBORS


# +-------------------------------------------+
# | Core Calculation Functions                |
# +-------------------------------------------+
"""
"""
function evoluate_under_T(pattern::PatternData, T::Float64, config::Dict)
    Δ_energy = 0.0
    succeed_updates = 0
    observe_patterns_quantity = 0
    average_Δ_energy = 0.0
    average_pattern = zeros(config["playground"]["_state_pattern_shape"])
    preheat_steps = config["evolution"]["steps_preheat"]
    evoluate_steps = config["evolution"]["steps_each_temperature"]
    # Preheat the system
    for _ in 1:preheat_steps
        pattern, δ_energy, update_succeed = 
            evoluate_one_step_under_T(pattern, T, config)
        Δ_energy += δ_energy
        succeed_updates += update_succeed
    end
    # Evoluate the system
    for i_evlouate in ProgressBar(1:evoluate_steps)
        pattern, δ_energy, update_succeed = 
            evoluate_one_step_under_T(pattern, T, config)
        Δ_energy += δ_energy
        succeed_updates += update_succeed
        # Observe the pattern
        if (0 == i_evlouate%config["evolution"]["steps_observe_interval"])
            average_pattern, average_Δ_energy, observe_patterns_quantity =
                update_average_pattern(
                    average_pattern, average_Δ_energy, 
                    observe_patterns_quantity, pattern, Δ_energy, config
                )
        end
    end
    # Return the result
    average_Δ_energy /= length(pattern)
    Δ_energy /= length(pattern)
    return pattern, Δ_energy, average_pattern, average_Δ_energy, succeed_updates
end


"""
"""
function evoluate_one_step_under_T(
    pattern::PatternData, T::Float64, config::Dict
):: Tuple{PatternData, Float64, Bool}
    states_quantity = config["energy"]["_states_quantity"]
    coord = random_select_cell_without_dead(pattern)
    new_state = random_select_new_state(states_quantity, pattern[coord...])
    δ_energy = calc_δ_energy(pattern, coord, new_state, config)
    # Decided accept the new pattern or not
    if accept_pattern_update(T, δ_energy)
        pattern = update_pattern(pattern, coord, new_state)
        return pattern, δ_energy, true
    end
    return pattern, 0.0, false
end


"""
"""
function random_select_cell(pattern_shape::Tuple)::Tuple
    return Tuple(rand(1:d) for d in pattern_shape)
end


"""
"""
function random_select_cell_without_dead(pattern::PatternData)::Tuple
    while true
        coord = random_select_cell(size(pattern))
        if DEAD_CELL_IDX != pattern[coord...]
            return coord
        end
    end
end


"""
    Randomly choice the state on the selected cell
"""
function random_select_new_state(states_quantity::Int, curr_state::Int)
    return (rand(1:states_quantity-1) + curr_state - 1) % states_quantity + 1
end


"""
"""
function calc_δ_energy(
    pattern::PatternData, coord::Tuple, new_state::Int, config::Dict
)::Float64
    δ_energy = 0.0
    δ_energy += 
        calc_nearest_neighbors_energy(pattern, coord, new_state, config)
    δ_energy += 
        calc_nearest_dead_neighbor_energy(pattern, coord, new_state, config)
    δ_energy += calc_external_E_energy(pattern, coord, new_state, config)
    return δ_energy
end


"""
"""
function calc_nearest_neighbors_energy(
    pattern::PatternData, coord::Tuple, new_state::Int, config::Dict
)::Float64
    old_state = pattern[coord...]
    nearest_coords = get_nearby_coord(coord, NORM_NN, size(pattern))
    nearest_neighbors_states = map(x -> pattern[x...], nearest_coords)
    available_states = config["energy"]["available_states"]
    J1 = config["energy"]["Js"][1]
    # Get state vectors
    old_state_vec = available_states[old_state,:]
    new_state_vec = available_states[new_state,:]
    nn_states_vecs = available_states[nearest_neighbors_states,:]
    # Calc the energy energy change
    state_vec_change = new_state_vec - old_state_vec
    δ_energy = J1 * sum(nn_states_vecs * state_vec_change)
    return δ_energy
end


"""
"""
function get_nearby_coord(
    coord::Tuple, nearby_movements::Vector, pattern_shape::Tuple
)::Vector
    nearby_coords = map(x -> x .+ coord, nearby_movements)
    nearby_coords = map(x -> mod.(x.-1, pattern_shape).+1, nearby_coords)
    return nearby_coords
end


"""
"""
function calc_nearest_dead_neighbor_energy(
    pattern::PatternData, coord::Tuple, new_state::Int, config::Dict
)::Float64
    # Old state
    old_state = pattern[coord...]
    nearest_coords = get_nearby_coord(coord, NORM_NN, size(pattern))
    nearest_neighbors_states = map(x -> pattern[x...], nearest_coords)
    available_states = config["energy"]["available_states"]
    D1 = config["energy"]["Ds"][1]
    #
    dead_mask = map(x -> DEAD_CELL_IDX == x, nearest_neighbors_states)
    dead_nn_pos_vecs = 
        map(x -> ifelse(x[1], x[2], nothing), zip(dead_mask, NORM_NN))
    dead_nn_pos_vecs = filter(!isnothing, dead_nn_pos_vecs)
    if 0 == length(dead_nn_pos_vecs) 
        return 0.0
    end
    # Get state vectors
    old_state_vec = available_states[old_state,:]
    new_state_vec = available_states[new_state,:]
    #
    state_vec_change = new_state_vec - old_state_vec
    δ_energy = D1 * sum(map(x -> dot(state_vec_change, x), dead_nn_pos_vecs))
    #
    return δ_energy 
end


function calc_external_E_energy(
    pattern::PatternData, coord::Tuple, new_state::Int, config::Dict
)::Float64
    # Electrostatic field
    old_state = pattern[coord...]
    E_ext = config["energy"]["E_ext"]
    E_ext_val = E_ext[1]
    E_ext_vec = E_ext[2:4]
    available_states = config["energy"]["available_states"]
    # Get state vectors
    old_state_vec = available_states[old_state,:]
    new_state_vec = available_states[new_state,:]
    # External electric field part
    state_vec_change = new_state_vec - old_state_vec
    δ_energy = E_ext_val * dot(state_vec_change, E_ext_vec)
    #
    return δ_energy
end


"""
"""
function accept_pattern_update(T::Float64, δ_energy::Float64)
    accept_probability = boltzmann_distribuiton_condition(T, δ_energy)
    return rand() < accept_probability
end


"""
"""
function boltzmann_distribuiton_condition(T::Float64, δ_energy::Float64)
    return exp(-δ_energy / (K_B * T))
end


"""
"""
function update_pattern(
    pattern::PatternData, coord::Tuple, new_state::Int
)::PatternData
    pattern[coord...] = new_state
    return pattern
end


"""
"""
function update_average_pattern(
    average_pattern::PatternStatesData, average_Δ_energy::Float64, 
    observe_patterns_quantity::Int, pattern::PatternData,
    Δ_energy::Float64, config::Dict
)
    available_states = config["energy"]["available_states"]
    next_observe_patterns_quantity = observe_patterns_quantity + 1
    curr_pattern = available_states[pattern,:]
    average_pattern = (average_pattern * observe_patterns_quantity + curr_pattern) / next_observe_patterns_quantity
    average_Δ_energy = (average_Δ_energy * observe_patterns_quantity + Δ_energy) / next_observe_patterns_quantity
    return average_pattern, average_Δ_energy, next_observe_patterns_quantity
end


end # module CraftCore