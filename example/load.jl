using MonteCraft

path = "./2024-09-26_23-18-43-460.run/mc_data.ser"

mc_data = MonteCraft.CraftData.load_data(path)

print(mc_data.average_energys)

