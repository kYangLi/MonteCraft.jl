using Logging
using LoggingExtras

export decorate_logging


"""
    decorate_logging(min_level, log_file_name)
"""
function decorate_logging(; min_level::Base.CoreLogging.LogLevel=Info, log_file_name::Union{String,Nothing}=nothing)
    head_color_map = Dict(
        Debug => 0,
        Info => :cyan,
        Warn => :yellow,
        Error => :red,
    )
    msg_color_map = Dict(
        Debug => 0,
        Info => :white,
        Warn => :yellow,
        Error => :red,
    )
    log_name = isnothing(log_file_name) ? stdout : log_file_name
    logger = FormatLogger(log_name) do io, args
        printstyled(io, "[ $(args.level) | ", color=head_color_map[args.level])
        if args.level == Debug
            printstyled(io, "$(args._module) | ", color=head_color_map[args.level])
        end
        printstyled(io, "$(args.message)", color=msg_color_map[args.level])
        if args.level in [Warn, Error]
            println(io, "")
            printstyled(io, "  L. @ $(args._module) | $(args.file):$(args.line)", color=232)
        end
        println(io, "")
    end
    global_logger(MinLevelLogger(logger, min_level))
end