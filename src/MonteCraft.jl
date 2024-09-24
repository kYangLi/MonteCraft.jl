module MonteCraft
    include("CONSTANT.jl")
    include("logging.jl")
    include("misc.jl")

    include("config.jl")

    include("craft_core.jl")
    include("craft_data.jl")
    include("craft_observe.jl")

    include("craft.jl")

    # Export useful objects
    using .CraftData
    export MonteCraftData

    using .Craft
    export evolution

    # Init function
    function __init__()
        decorate_logging(; min_level=Info)
    end

end # module MonteCraft
