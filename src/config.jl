module Config

using TOML

using ..MonteCraft.MiscTools: normalize, vecvec2matrix

export read_config

function read_config(toml_file_path::String)::Dict
    config = TOML.parsefile(toml_file_path)
    config = parse_pattern_info(config)
    config = parse_evolution_info(config)
    config = parse_states_info(config)
    return config
end


"""
"""
function parse_pattern_info(config::Dict)::Dict
    x_size = config["playground"]["x_size"]
    y_size = config["playground"]["y_size"]
    z_size = config["playground"]["z_size"]
    config["playground"]["_pattern_shape"] = (x_size, y_size, z_size)
    config["playground"]["_pattern_size"] = x_size * y_size * z_size
    return config
end


"""
"""
function parse_evolution_info(config::Dict)::Dict
    evolution_steps = config["evolution"]["steps_each_temperature"]
    obs_invterval = config["evolution"]["steps_observe_interval"]
    observe_quantity = max(1, evolution_steps ÷ obs_invterval)
    config["evolution"]["_observe_quantity"] = observe_quantity
    return config
end


"""
"""
function parse_states_info(config::Dict)
    # Transfer the states_quantity from vec-vec to matrix
    avail_states = config["energy"]["available_states"]
    avail_states = map(x -> normalize(x), avail_states)
    avail_states = vecvec2matrix(avail_states)
    config["energy"]["available_states"] = avail_states
    # Get necessary information
    states_shape = size(config["energy"]["available_states"])
    states_quantity = states_shape[1]
    state_length = states_shape[2]
    # Update!
    config["energy"]["_states_quantity"] = states_quantity
    config["energy"]["_state_length"] = state_length
    config["playground"]["_state_pattern_shape"] = (
        config["playground"]["x_size"],
        config["playground"]["y_size"],
        config["playground"]["z_size"],
        state_length
    )
    return config
end


end # Config module