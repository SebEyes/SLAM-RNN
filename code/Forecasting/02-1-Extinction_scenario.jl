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

## Collect last known status of the assemblage
last_true_status = last(diversity_data) |> DataFrame
last_true_status = permutedims(last_true_status)
last_true_status = vec(Array(last_true_status))

## Collect MF list
MF_list = names(diversity_data)


## Start Loop
for extinct_MF in 1:size(MF_list)[1]
    extinct_MF_verbatim = MF_list[extinct_MF]
    @info("$extinct_MF_verbatim goes extinct!")

    # Initialise extinction
    last_status = last_true_status
    last_status[extinct_MF] = 0

    forecasts = []

    for future in 1:prediction
        @info("Predicting season $future up to $prediction")
        last_status = IA_model(last_status)
        last_status[extinct_MF] = 0

        append!(forecasts, last_status)
    end

    forecasts = permutedims(reshape(forecasts, size(MF_list)[1], prediction))
    forecasts = DataFrame(forecasts, MF_list)

    file_name = "data/extinction_scenarios/"*extinct_MF_verbatim*".csv"

    CSV.write(file_name, forecasts)
end
