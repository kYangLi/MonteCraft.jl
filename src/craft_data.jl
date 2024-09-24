module CraftData

using Random
using Statistics

using ..MonteCraft
using ..MonteCraft.Config: read_config
using ..MonteCraft.CraftCore: random_select_cell_without_dead, update_pattern
using ..MonteCraft.MiscTools: linear_sequence, log_sequence

export MonteCraftData, calc_average_state

mutable struct MonteCraftData
    config::Dict{String, Any}
    #
    Ts::Vector{Float64}    
    #
    pattern::PatternData
    average_Δ_energys::Vector{Float64}
    average_energys::Vector{Float64}
    average_patterns::Vector{PatternStatesData}
    average_states::Vector{Vector{Float64}}
    succeed_updates::Vector{Int}
    energy_ref::Float64
    #
    start_time::Float64
    last_time::Float64
    end_time::Float64
end


function MonteCraftData(config_file_path::String)
    # Read in the config
    config = read_config(config_file_path)
    # Update the Random seed
    set_random_seed!(config)
    # Parameters
    Ts = get_temperature_range(config)
    pattern = get_init_pattern(config)
    Δ_energys = zeros(Float64, length(Ts))
    average_energys = zeros(Float64, length(Ts))
    average_patterns = 
        map(_ -> zeros(config["playground"]["_state_pattern_shape"]), Ts)
    average_states = 
        map(_ -> zeros(Float64, config["energy"]["_state_length"]), Ts)
    succeed_updates = zeros(Int, length(Ts))
    energy_ref = 0.0
    curr_time = time()
    return MonteCraftData(
        config, Ts, pattern, Δ_energys, average_energys, average_patterns,
        average_states, succeed_updates, energy_ref,
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
function get_init_pattern(config::Dict)::PatternData
    # Init the pattern config
    pattern_shape = config["playground"]["_pattern_shape"]
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
    return pattern
end


"""
"""
function set_dead_pattern(pattern::PatternData, config::Dict)
    # TODO: periodic dead pattern order and opt this function
    dead_cell_idx = config["energy"]["_dead_cell_idx"]
    for _ in 1:config["playground"]["dead_cell_quantity"]
        coord = random_select_cell_without_dead(pattern, dead_cell_idx)
        pattern = update_pattern(pattern, coord, dead_cell_idx)
    end
    return pattern
end


"""
"""
function calc_average_state(state_pattern::PatternStatesData; dims=(1,2,3))
    return dropdims(mean(state_pattern; dims=dims); dims=dims)
end


end # Module CraftData