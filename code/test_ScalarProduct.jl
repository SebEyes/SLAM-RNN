using Pkg
# Pkg.add("LinearAlgebra")
using LinearAlgebra
using DataFrames
using CSV

### Import data
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ","
) |> DataFrame

## Remove MF 116 and 19
diversity_data = select(
    diversity_data, 
    Not([:2, :16])
)

model_output = CSV.File(
    "data/result_model_V5_100000.csv",
    delim = ","
) |> DataFrame

#remove forecast data
model_output = model_output[model_output.time_step .> 34,:]

V102_real = diversity_data[diversity_data.time_step .> 34 ,1]
V102_model = model_output[:,1]

scalar_product = dot(V102_real, V102_model)

cos_angle = scalar_product / (norm(V102_real) * norm(V102_model))

accuracy = 1-(cos_angle * (norm(V102_model) - norm(V102_real))/((norm(V102_model) + norm(V102_real))))