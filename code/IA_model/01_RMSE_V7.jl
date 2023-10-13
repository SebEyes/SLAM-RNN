using CSV, DataFrames

## Load test dataset
diversity_data = CSV.File(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    delim = ";"
) |> DataFrame
select!(diversity_data, Not([:sampling_period, :step]))
diversity_data = diversity_data[2:40,:] #remove first data, not included in RNN output

## Load RNN data
forecasted_data = CSV.File(
    "data/results_scenario/S0[best_model_selection]/V9/Acc_50/modelV9_best_output_model.csv",
) |> DataFrame

### Assessing Accuracy (RMSE)
accuracy_list = []
for MF in 1:ncol(diversity_data)
    model_data = forecasted_data[:,MF]
    real_data = diversity_data[:,MF]

    acc_MF = rmsd(model_data, real_data)

    append!(
        accuracy_list,
        acc_MF
    )
end


accuracy_result = DataFrame(
    IA_RMSE = accuracy_list,
    MF = names(diversity_data)
)


CSV.write("data/results_scenario/S0[best_model_selection]/RMSE_V9.csv", accuracy_result)