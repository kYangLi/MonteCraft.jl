using MonteCraft

data_path = "/home/xush/test_all/BTO_ALL/julia/test_data/2024-09-26_23-20-13-003.run/mc_data.ser"

mc_data = MonteCraft.CraftData.load_data(path)

print(mc_data.Ts)