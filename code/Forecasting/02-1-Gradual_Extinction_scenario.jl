## Package
using Flux, BSON
using CSV, DataFrames

## Constants
prediction = 4*10 #10 next years
extinction_proportion = vec(0:10:100)

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

## Start Extinction Loop
for extinct_MF in 1:size(MF_list)[1]

    for reduction in extinction_proportion
        reduction_verbatim = string(reduction)*"_%"

        reduction = reduction/100

        extinct_MF_verbatim = MF_list[extinct_MF]

        @info("$extinct_MF_verbatim is reduced by $reduction_verbatim")

        ## Collect last known status of the assemblage
        last_status = last(diversity_data) |> DataFrame

        ## Initialise extinction
        last_status[!,extinct_MF] = last_status[!,extinct_MF] - last_status[!,extinct_MF]*reduction

        last_status = permutedims(last_status)
        last_status = vec(Array(last_status))
        last_status = Float32.(last_status)
        
        forecasts = []
        append!(forecasts, last_status)
        # forecasts = Float32.(forecasts)

        for future in 2:prediction
            # @info("Predicting season $future up to $prediction")
            last_status = Float32.(IA_model(last_status))

            append!(forecasts, last_status)
        end

        forecasts = permutedims(reshape(forecasts, size(MF_list)[1], prediction))
        forecasts = DataFrame(forecasts, MF_list)

        file_name = "data/extinction_scenarios/gradual_extinction/"*extinct_MF_verbatim*"_"*reduction_verbatim*".csv"

        CSV.write(file_name, forecasts)
    end
end