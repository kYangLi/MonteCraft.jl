using Dates
using Logging

using MonteCraft

# System constants
TIME_STAMP = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS-sss")

# Calculation constants
# - Config
CONFIG_PATH = joinpath(".", "config.toml")
# - Outputs
OUTPUT_PATH = joinpath(".", "$(TIME_STAMP).run")
LOG_PATH = joinpath(OUTPUT_PATH, "run.log")
CONFIG_SAVE_PATH = joinpath(OUTPUT_PATH, "config.toml")
DATA_BIN_PATH = joinpath(OUTPUT_PATH, "mc_data.ser")

# Make the log path
mkpath(OUTPUT_PATH)
decorate_logging(;min_level=Info, log_file_name=LOG_PATH)

# Calculate!
# - Init!
mc_data = MonteCraftData(CONFIG_PATH)
MonteCraft.Config.save_config(mc_data.config, CONFIG_SAVE_PATH)
# - Evolute!
evolution(mc_data, DATA_BIN_PATH)
MonteCraft.Config.save_config(mc_data.config, CONFIG_SAVE_PATH)

