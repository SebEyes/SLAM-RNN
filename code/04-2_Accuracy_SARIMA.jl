using CSV, DataFrames

include("01_Julia-RNN_model_V7.jl")

## Load SARIMA output test data
SARIMA_fitting = CSV.File(
    "data/SARIMA/output_SARIMA.csv",
    delim = ";"
) |> DataFrame 

## Load training dataset
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame  
diversity_data = diversity_data[27:36,:]
select!(diversity_data, Not(:time_step))

### Assessing Accuracy
accuracy_list = []
for MF in 1:ncol(diversity_data)
    SARIMA_data = SARIMA_fitting[:,MF]
    real_data = diversity_data[:,MF]

    acc_MF = Accuracy(SARIMA_data,real_data)

    append!(
        accuracy_list,
        acc_MF
    )
end


accuracy_result = DataFrame(
    SARIMA_accuracy = accuracy_list,
    MF = names(diversity_data)
)

CSV.write("data/SARIMA/accuracy_SARIMA.csv", accuracy_result)

mean(accuracy_result.SARIMA_accuracy)