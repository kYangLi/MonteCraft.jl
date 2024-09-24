module Craft


using ..MonteCraft
using ..MonteCraft.CraftCore: evoluate_under_T
using ..MonteCraft.CraftData: MonteCraftData, calc_average_state
using ..MonteCraft.CraftObserve: save_pattern

export evolution

"""
Evolute the pattern from one temperature to the end.
"""
function evolution(mc_data::MonteCraftData)
    mc_data.energy_ref = 0.0
    # Loop for each annealing
    for (i_T, T) in enumerate(mc_data.Ts)
        # Basic Info. Output
        println("[info] ($(i_T)/$(length(mc_data.Ts))) T: $(T) K")
        # Evolution Step!
        mc_data.pattern, Δ_energy, average_pattern, average_Δ_energy, succeed_updates = evoluate_under_T(mc_data.pattern, T, mc_data.config)
        # Process the energy terms
        average_energy = mc_data.energy_ref + average_Δ_energy
        mc_data.energy_ref += Δ_energy
        mc_data.energys[i_T] = average_energy
        # Process the average pattern terms
        average_state = calc_average_state(average_pattern)
        mc_data.states[i_T] = average_state
        # Output the simulation results
        println("[info] Succeed-Steps / All-Steps : $(succeed_updates) / $(mc_data.config["evolution"]["steps_each_temperature"]+mc_data.config["evolution"]["steps_preheat"])")
        println("[info] Current Energy Decay : $(average_Δ_energy) eV/cell")
        println("[info] Current Total Energy : $(average_energy) eV/cell")
        # Logging and show
        save_pattern(average_pattern, mc_data, i_T, T)
        _print_time_cost(mc_data)
        print("")
    end
end


"""
"""
function _print_time_cost(mc_data::MonteCraftData)
    curr_time = time()
    last_time = mc_data.last_time
    cost_time = curr_time - last_time
    cost_time = round(cost_time, digits=2)
    println("[info] Time Cost: $(cost_time) s")
    mc_data.last_time = curr_time
end


end # Module Craft