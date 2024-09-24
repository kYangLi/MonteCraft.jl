using MonteCraft

decorate_logging(;log_file_name="./demo.log")

mc_data = MonteCraftData("./config.toml")
evolution(mc_data)