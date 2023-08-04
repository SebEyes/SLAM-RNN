### Scenario 0: Best model selection
include("S0[best_model_selection].jl")

scenario_S0(100,50_000) 

### Scenario 1: Temporal autocorrelation
include("S1[temporal autocorrelation].jl")

scenario_S1(2,500)