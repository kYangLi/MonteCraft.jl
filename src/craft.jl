module Craft

using ..MonteCraft
using ..MonteCraft.CraftCore: evoluate_under_T
using ..MonteCraft.CraftData: MonteCraftData, calc_average_state, save_data

export evolution


"""
Evolute the pattern from one temperature to the end.
"""
function evolution(mc_data::MonteCraftData, mc_data_save_path::String="")
    mc_data.energy_ref = 0.0
    # Loop for each annealing
    for (i_T, T) in enumerate(mc_data.Ts)
        # Basic Info. Output
        println("Processing [ $(i_T) / $(length(mc_data.Ts)) ] ...")
        @info "T_$(i_T) = $(T) K"
        # Evolution Step!
        pattern, Δ_energy, average_pattern, average_Δ_energy, succeed_updates = 
            evoluate_under_T(mc_data.pattern, T, mc_data.config)
        # Save the evolution results
        mc_data.pattern = pattern
        mc_data.average_Δ_energys[i_T] = average_Δ_energy
        mc_data.average_energys[i_T] = average_Δ_energy + mc_data.energy_ref
        mc_data.average_patterns[i_T] = average_pattern
        mc_data.average_states[i_T] = calc_average_state(average_pattern)
        mc_data.succeed_updates[i_T] = succeed_updates
        mc_data.energy_ref += Δ_energy
        # Output the simulation results
        logger_for_each_T(mc_data, i_T)
        if mc_data_save_path != ""
            save_data(mc_data, mc_data_save_path)
        end
    end
end


"""
"""
function logger_for_each_T(mc_data::MonteCraftData, i_T::Int)
    succeed_updates = mc_data.succeed_updates[i_T]
    total_steps = 
        mc_data.config["evolution"]["steps_each_temperature"] + 
        mc_data.config["evolution"]["steps_preheat"]
    # - 
    abs_J1 = abs(mc_data.config["energy"]["Js"][1])
    average_Δ_energy = mc_data.average_Δ_energys[i_T] / abs_J1
    average_Δ_energy = round(average_Δ_energy, digits=3)
    average_energy = mc_data.average_energys[i_T] / abs_J1
    average_energy = round(average_energy, digits=3)
    average_state = mc_data.average_states[i_T]
    average_state *= sqrt(length(average_state))
    average_state = map(x -> round(x, digits=3), average_state)
    #
    @info "Succeed Steps: $(succeed_updates) / $(total_steps)"
    @info "Current Energy Decay: $(average_Δ_energy) J1/cell"
    @info "Current Total Energy: $(average_energy) J1/cell"
    @info "Current Average State: $(average_state)"
    _print_time_cost(mc_data)
    @info ""
end


"""
"""
function _print_time_cost(mc_data::MonteCraftData)
    curr_time = time()
    last_time = mc_data.last_time
    cost_time = curr_time - last_time
    cost_time = round(cost_time, digits=2)
    @info ("Time Cost: $(cost_time) s")
    mc_data.last_time = curr_time
    mc_data.end_time = curr_time
end


end # Module Craft