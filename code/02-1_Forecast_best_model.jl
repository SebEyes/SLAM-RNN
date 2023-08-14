## Package
using Flux, BSON
using CSV, DataFrames
using LinearAlgebra

## Load model architecture
BSON.@load "data/results_scenario/S0[best_model_selection]/output_V6_best.bson" model

## Load training dataset
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame   

x_train = 1:26
x_test = 27:nrow(diversity_data)
test_data = diversity_data[x_test,:]
x_test = test_data.time_step

####
## Model forecasts
####
number_prediction = 8 #Forecast the next 8 seasons
prediction = []
out_features = ncol(diversity_data) -1 #number of species to forecast

time_step = minimum(diversity_data.time_step):maximum(diversity_data.time_step)+number_prediction


for value in time_step
    value = [value]
    # println(value)
    append!(prediction, model(value))
end

output = DataFrame(
    reshape(
        prediction,
        (out_features, nrow(diversity_data)+number_prediction)),
        :auto)

output = permutedims(output)
output.time_step = time_step
rename!(output, names(diversity_data))

CSV.write("data/forecast best modelV6/forecasted_data.csv", output)