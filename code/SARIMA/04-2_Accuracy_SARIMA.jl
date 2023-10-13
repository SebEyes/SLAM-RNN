using CSV, DataFrames

include("/home/sebastien/Documents/GBA/SLAM-RNN/code/IA_model/01_Julia-RNN_model_V7.jl")

## Load SARIMA output test data
SARIMA_fitting = CSV.File(
    "data/SARIMA/output_SARIMA.csv",
    delim = ";"
) |> DataFrame
select!(SARIMA_fitting, Not(:step))

## Load test dataset
diversity_data = CSV.File(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    delim = ";"
) |> DataFrame 
select!(diversity_data, Not([:step, :sampling_period]))
diversity_data_test = diversity_data[31:40,:]


### Assessing Accuracy (Vector based)
accuracy_list = []
for MF in 1:ncol(diversity_data)
    SARIMA_data = SARIMA_fitting[31:40,MF]
    real_data = diversity_data_test[:,MF]
    if (trunc(mean(SARIMA_data), digits=4) == trunc(SARIMA_data[1], digits = 4))
        acc_MF = NaN
    else
        acc_MF = Accuracy(SARIMA_data,real_data)
    end

    append!(
        accuracy_list,
        acc_MF
    )
end


accuracy_result = DataFrame(
    SARIMA_accuracy = accuracy_list,
    MF = names(diversity_data)
)


accuracy_result.acc_missing = any.(i -> !isnan(i), accuracy_result.SARIMA_accuracy)

acc_available = accuracy_result[any.(accuracy_result.acc_missing),:]
mean_acc = mean(acc_available.SARIMA_accuracy)

CSV.write("data/SARIMA/accuracy_SARIMA.csv", accuracy_result)

### Assessing Accuracy (RMSE)
accuracy_list = []
for MF in 1:ncol(diversity_data)
    SARIMA_data = SARIMA_fitting[:,MF]
    real_data = diversity_data[:,MF]

    acc_MF = rmsd(SARIMA_data, real_data)

    append!(
        accuracy_list,
        acc_MF
    )
end


accuracy_result = DataFrame(
    SARIMA_RMSE = accuracy_list,
    MF = names(diversity_data)
)


CSV.write("data/SARIMA/RMSE_SARIMA.csv", accuracy_result)