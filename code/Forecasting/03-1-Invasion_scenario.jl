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

# Load info about MF
MF_info = CSV.File(
    "data/diversity_data/SuppS2_MF_Info.csv",
    delim = ";"
) |> DataFrame

MF_exotic = select(
    MF_info,
    :MF,
    :establishmentMeans
)
MF_exotic = MF_exotic[MF_exotic.establishmentMeans .== "I",:MF]
MF_exotic = string.(MF_exotic)
MF_exotic = "MF".*MF_exotic


## Start Loop
for exo_MF in 1:size(MF_list)[1]

    exo_MF_verbatim = MF_list[exo_MF]

    if exo_MF_verbatim in MF_exotic
        @info("$exo_MF_verbatim is exotic!")
        @info("$exo_MF_verbatim invades!")

        ## Collect last known status of the assemblage
        last_status = last(diversity_data) |> DataFrame
        
        # Initialise invasion
        if last_status[!,exo_MF] == 0
            last_status[!,exo_MF] = 1
        end
        last_status[!,exo_MF] = last_status[!,exo_MF]*10

        last_status = permutedims(last_status)
        last_status = vec(Array(last_status))
        last_status = Float32.(last_status)

        forecasts = []
        append!(forecasts, last_status)
        forecasts = Float32.(forecasts)

        for future in 1:prediction
            @info("Predicting season $future up to $prediction")
            last_status = Float32.(IA_model(last_status))
            # last_status[exo_MF] = last_status[exo_MF]*10

            append!(forecasts, last_status)
        end

        forecasts = permutedims(reshape(forecasts, size(MF_list)[1], prediction+1))
        forecasts = DataFrame(forecasts, MF_list)

        file_name = "data/invasion_scenarios/"*exo_MF_verbatim*".csv"

        CSV.write(file_name, forecasts)
    else
        @info("$exo_MF_verbatim is indigenous!")
    end
end