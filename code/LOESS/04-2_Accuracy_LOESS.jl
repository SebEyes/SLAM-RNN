using CSV, DataFrames

include("/home/sebastien/Documents/GBA/SLAM-RNN/code/IA_model/01_Julia-RNN_model_V7.jl")

## Load LOESS output test data
LOESS_fitting = CSV.File(
    "data/LOESS/output_LOESS.csv",
    delim = ";"
) |> DataFrame
select!(LOESS_fitting, Not(:step))

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
    LOESS_data = LOESS_fitting[31:40,MF]
    real_data = diversity_data_test[:,MF]
    acc_MF = Accuracy(LOESS_data,real_data)

    append!(
        accuracy_list,
        acc_MF
    )
end


accuracy_result = DataFrame(
    LOESS_accuracy = accuracy_list,
    MF = names(diversity_data)
)


accuracy_result.acc_missing = any.(i -> !isnan(i), accuracy_result.LOESS_accuracy)

acc_available = accuracy_result[any.(accuracy_result.acc_missing),:]
mean_acc = mean(acc_available.LOESS_accuracy)

CSV.write("data/LOESS/accuracy_LOESS.csv", accuracy_result)

### Assessing Accuracy (RMSE)
accuracy_list = []
for MF in 1:ncol(diversity_data)
    LOESS_data = LOESS_fitting[:,MF]
    real_data = diversity_data[:,MF]

    acc_MF = rmsd(LOESS_data, real_data)

    append!(
        accuracy_list,
        acc_MF
    )
end


accuracy_result = DataFrame(
    LOESS_RMSE = accuracy_list,
    MF = names(diversity_data)
)


CSV.write("data/LOESS/RMSE_LOESS.csv", accuracy_result)