using Pkg
# Pkg.add("LinearAlgebra")
using LinearAlgebra
using DataFrames
using CSV

### Import data
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame

model_output = CSV.File(
    "data/results_scenario/S0[best_model_selection]/modelV6_best_output_model.csv",
    delim = ","
) |> DataFrame


V102_real = diversity_data[28:36,1]
V102_model = model_output[28:36,1]

scalar_product = dot(V102_real, V102_model)

cos_angle = scalar_product / (norm(V102_real) * norm(V102_model))

accuracy = 1-(cos_angle * abs((norm(V102_model) - norm(V102_real)))/((norm(V102_model) + norm(V102_real))))