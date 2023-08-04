### Environment gestion
using Pkg
Pkg.activate(".")
Pkg.instantiate()

### Scenario 0: Best model selection
include("S0[best_model_selection].jl")

scenario_S0(100,50_000) 

### Scenario 1: Temporal autocorrelation
include("S1[temporal autocorrelation].jl")

scenario_S1(50,50_000)

### Scenario 2: Testing different training windows
include("S2[Training windows].jl")

scenario_S2(3, 50_000)
scenario_S2(5, 50_000)
scenario_S2(7, 50_000)