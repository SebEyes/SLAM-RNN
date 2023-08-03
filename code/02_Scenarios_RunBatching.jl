### Scenario 0: Best model selection
include("S0[best_model_selection].jl")

scenario_S0(number_runs = 10, epochs = 500) 

### Scenario 1: Temporal autocorrelation
include("S1[temporal autocorrelation].jl")

scenario_S1(number_runs = 2, epochs = 500)