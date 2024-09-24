module CraftData

using Random
using Statistics

using ..MonteCraft
using ..MonteCraft.Config: read_config
using ..MonteCraft.CraftCore: random_select_cell_without_dead, update_pattern
using ..MonteCraft.MiscTools

export MonteCraftData, calc_average_state

mutable struct MonteCraftData
    config::Dict{String, Any}
    #
    pattern::PatternData
    energy_ref::Float64
    Ts::Vector{Float64}
    energys::Vector{Float64}
    states::Vector{Vector{Float64}}
    #
    start_time::Float64
    last_time::Float64
    end_time::Float64
end


function MonteCraftData(config_file_path::String)
    config = read_config(config_file_path)
    # Update the Random seed
    set_random_seed!(config)
    # Transfer the states_quantity from vec-vec to matrix
    config = process_available_states(config)
    # Get pattern info.
    pattern, config = get_pattern(config)
    # Temperature list
    Ts = get_temperature_range(config)
    energys = zeros(Float64, length(Ts))
    states = map(_ -> zeros(Float64, config["energy"]["_state_length"]), Ts)
    #
    curr_time = time()
    return MonteCraftData(
        config, pattern, 0.0, Ts, energys, states,
        curr_time, curr_time, curr_time
    )
end


"""
"""
function set_random_seed!(config::Dict)
    rng_seed = config["random"]["seed"]
    Random.seed!(rng_seed)
end


"""
"""
function process_available_states(config::Dict)
    # Transfer the states_quantity from vec-vec to matrix
    avail_states = config["energy"]["available_states"]
    avail_states = map(x -> normalize(x), avail_states)
    avail_states = vecvec2matrix(avail_states)
    config["energy"]["available_states"] = avail_states
    # Update the states_quantity
    config["energy"]["_states_quantity"] = 
        size(config["energy"]["available_states"])[1]
    config["energy"]["_state_length"] = 
        size(config["energy"]["available_states"])[2]
    return config
end

"""
"""
function get_pattern_shape(config::Dict)
    pattern_x_size = config["playground"]["x_size"]
    pattern_y_size = config["playground"]["y_size"]
    pattern_z_size = config["playground"]["z_size"]
    return (pattern_x_size, pattern_y_size, pattern_z_size)
end


"""
"""
function get_state_pattern_shape(config::Dict)
    pattern_size = get_pattern_shape(config)
    state_length = size(config["energy"]["available_states"])[2]
    return (pattern_size..., state_length)
end


"""
"""
function get_pattern(config::Dict)::Tuple{PatternData, Dict}
    # Get pattern info.
    pattern_shape = get_pattern_shape(config)
    state_pattern_shape = get_state_pattern_shape(config)
    config["playground"]["_pattern_shape"] = pattern_shape
    config["playground"]["_state_pattern_shape"] = state_pattern_shape
    # Init the pattern config
    init_mode = config["playground"]["init_mode"]
    states_quantity = config["energy"]["_states_quantity"]
    # Init the pattern
    if init_mode == "zero"
        pattern = zeros(Int, pattern_shape)
    elseif init_mode == "random"
        pattern = rand(1:states_quantity, pattern_shape)
    else
        error("Unsupported initial mode: $(init_mode). Supported modes are: 'zero' and 'random'")
    end
    # Setup the dead pattern
    pattern = set_dead_pattern(pattern, config)
    return pattern, config
end


"""
"""
function set_dead_pattern(pattern::PatternData, config::Dict)
    # TODO: periodic dead pattern order and opt this function
    for _ in 1:config["playground"]["dead_cell_quantity"]
        coord = random_select_cell_without_dead(pattern)
        pattern = update_pattern(pattern, coord, DEAD_CELL_IDX)
    end
    return pattern
end


"""
"""
function get_temperature_range(config::Dict)
    T_start = config["temperature"]["start"]
    T_end = config["temperature"]["end"]
    T_decay_method = config["temperature"]["decay_method"]
    T_decay = config["temperature"]["decay"]
    #
    if T_decay_method == "linear"
        return linear_sequence(T_start, T_end+T_decay, T_decay)
    elseif T_decay_method == "log"
        return log_sequence(T_start, T_end*T_decay, T_decay)
    else
        error("Unsupported temperature decay method: $(T_decay_method). Supported methods are: 'linear' and 'log'")
    end
end


"""
"""
function calc_average_state(state_pattern::PatternStatesData; dims=(1,2,3))
    return dropdims(mean(state_pattern; dims=dims); dims=dims)
end



end # Module CraftData