using CSV, DataFrames

## Load test dataset
diversity_data = CSV.File(
    "data/diversity_data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame  
diversity_data = diversity_data[27:36,:]
select!(diversity_data, Not(:time_step))

## Load forecasted data
forecasted_data = CSV.File(
    "data/results_scenario/S0[best_model_selection]/modelV7_output.csv",
) |> DataFrame
forecasted_data = forecasted_data[26:35,:] 

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


CSV.write("data/results_scenario/S0[best_model_selection]/RMSE_V7.csv", accuracy_result)