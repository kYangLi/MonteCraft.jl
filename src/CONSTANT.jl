export PatternData, PatternStatesData
export K_B, NEAREST_NEIGHBORS, DEAD_CELL_IDX

# The necessary data types
const PatternData = Array{Int, 3}
const PatternStatesData = Array{Float64, 4}


# Math and physical constant
# - Boltzmann constant
const K_B = 8.61733034E-5 # eV/K

# Simulation system related
const NEAREST_NEIGHBORS = [
    [1,0,0], [-1,0,0], [0,1,0], [0,-1,0], [0,0,1], [0,0,-1]
]
const DEAD_CELL_IDX = -4242


# # Filesystem
# # - Data
# const PATTERN_FOLDER = "pattern"
# const PATTERN_PIC_TAG = "pattern"
# const OBSERVE_FILE = "observe-process.pdf"
# const DATA_FORMAT = "dat"
# # - Plot
# const PLOT_FORMAT = "png"
# const PLOT_DPI = 300

