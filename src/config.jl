module Config

using TOML

using ..MonteCraft.MiscTools: normalize, vecvec2matrix

export read_config


"""
"""
function save_config(config::Dict, toml_file_path::String)
    open(toml_file_path, "w") do fio
        TOML.print(fio, config)
    end
end


"""
"""
function read_config(toml_file_path::String)::Dict
    config = TOML.parsefile(toml_file_path)
    config = parse_pattern_info(config)
    config = parse_dead_cell_info(config)
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
function parse_dead_cell_info(config::Dict)::Dict
    N_dead = config["playground"]["dead_cell_quantity"]
    if N_dead <= 0
        return config
    end
    #
    periodic_unit_size = config["playground"]["dead_cell_periodic_unit"]
    unit_x = periodic_unit_size[1]
    unit_y = periodic_unit_size[2]
    unit_z = periodic_unit_size[3]
    x_size = config["playground"]["x_size"]
    y_size = config["playground"]["y_size"]
    z_size = config["playground"]["z_size"]
    factor_x = x_size ÷ unit_x
    factor_y = y_size ÷ unit_y
    factor_z = z_size ÷ unit_z
    pattern_size = x_size * y_size * z_size
    factor = factor_x * factor_y * factor_z
    factors = (factor_x, factor_y, factor_z)
    #
    if factor * unit_x * unit_y * unit_z < pattern_size
        error("The dead cell periodic unit $(periodic_unit_size) cannot devided the pattern $((x_size, y_size, z_size))!")
    end
    #
    factor = factor_x * factor_y * factor_z
    if 0 != N_dead%factor
        error("The dead cell quantity $(N_dead) cannot be devided by unit factor $(factors)!")
    end
    config["playground"]["_dead_cell_quantity_each_unit"] = N_dead ÷ factor
    config["playground"]["_dead_cell_unit_factors"] = factors
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
    dead_state = config["energy"]["daed_state"]
    full_states = [avail_states..., dead_state]
    avail_states = map(x -> normalize(x), avail_states)
    avail_states = vecvec2matrix(avail_states)
    full_states = map(x -> normalize(x), full_states)
    full_states = vecvec2matrix(full_states)
    config["energy"]["available_states"] = avail_states
    config["energy"]["_full_states"] = full_states
    # Get necessary information
    states_shape = size(config["energy"]["available_states"])
    states_quantity = states_shape[1]
    state_length = states_shape[2]
    # Update!
    config["energy"]["_states_quantity"] = states_quantity
    config["energy"]["_state_length"] = state_length
    config["energy"]["_dead_cell_idx"] = states_quantity + 1
    config["playground"]["_state_pattern_shape"] = (
        config["playground"]["x_size"],
        config["playground"]["y_size"],
        config["playground"]["z_size"],
        state_length
    )
    return config
end


end # Config module