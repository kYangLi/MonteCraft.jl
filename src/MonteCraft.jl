module MonteCraft
    include("CONSTANT.jl")

    include("config.jl")
    include("misc.jl")

    include("craft_core.jl")
    include("craft_data.jl")
    include("craft_observe.jl")

    include("craft.jl")

    #
    using .CraftData
    export MonteCraftData

    using .Craft
    export evolution

end # module MonteCraft
