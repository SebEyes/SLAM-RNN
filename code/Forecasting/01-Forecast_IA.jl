## Package
using Flux, BSON
using CSV, DataFrames
using LinearAlgebra

include("01_Julia-RNN_model_V7.jl")

## Load model architecture
BSON.@load "data/results_scenario/S0[best_model_selection]/V9/Acc_50/output_V9_50.bson" model

## Load training dataset
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame  
diversity_data = select(diversity_data, Not(:time_step))

last_season_number = size(diversity_data)[1]
last_season = DataFrame(diversity_data[last_season_number,:])
last_season = Matrix(last_season)
last_season = permutedims(last_season)


####
## Model forecasts
####
number_prediction = 10 #Forecast the next 8 seasons
prediction = [model(last_season)]

for season in 1:number_prediction
    @info("Prediction number $season")
    append!(prediction, [model(last(prediction))])
end

output, _ = Input_format(prediction, false)

output = DataFrame(output,:auto)
output = permutedims(output)
rename!(output, names(diversity_data))


CSV.write("data/forecast best modelV7/forecasted_data.csv", output)