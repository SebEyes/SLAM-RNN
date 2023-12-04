## Package
using Flux, BSON
using CSV, DataFrames

## Constants
prediction = 4*10 #10 next years

## Load Model
BSON.@load "data/results_scenario/S0[best_model_selection]/V9/Acc_60/output_V9_60.bson" model
IA_model = model

## Load training dataset
diversity_data = CSV.File(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    delim = ";"
) |> DataFrame
# Saving time information
time_series_step = select(diversity_data, :step, :sampling_period)
diversity_data = select(diversity_data, Not([:step, :sampling_period]))
## Collect MF list
MF_list = names(diversity_data)


####
## Model forecasts
####
## Collect last known status of the assemblage
last_true_status = last(diversity_data) |> DataFrame
last_true_status = permutedims(last_true_status)
last_true_status = vec(Array(last_true_status))
last_true_status = Float32.(last_true_status)

last_status = last_true_status

forecasts = []
append!(forecasts, last_status)


for future in 2:prediction
    # @info("Predicting season $future up to $prediction")
    last_status = Float32.(IA_model(last_status))

    append!(forecasts, last_status)
end

forecasts = permutedims(reshape(forecasts, size(MF_list)[1], prediction))
forecasts = DataFrame(forecasts, MF_list)

CSV.write("data/forecast best modelV9/forecasted_data.csv", forecasts)