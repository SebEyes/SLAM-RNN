### Load model
include("01_Julia-RNN_model.jl")

####
## This script test the assumption that it exists a temporal autocorrelation between consecutive data
## If such an autocorrelation exists, the mean accuracy of the model with shuffled time step must be lower than the model using consecutive time step
####

### Import data
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame


name_model_list = ["V6_shuffle", "V6_sorted"]
epoch_number_list = [50000, 50000]
sorted = [false, true]
number_runs = 500 #one run is between 1 and 2 hours

accuracy_model = []

for run in 1:number_runs
    @info("Run number $run/$number_runs")
    for model_number in 1:size(name_model_list, 1)
        model_version = name_model_list[model_number]
        epoch_number = epoch_number_list[model_number]
        sorted_data = sorted[model_number]

        _, output_model, all_accuracy, mean_accuracy, loss_model = forecast_model(
        diversity_data, 
        epoch_number,
        model_version,
        8,
        sorted_data
        )

        @info ("Mean Accuracy = $mean_accuracy")
        append!(accuracy_model,mean_accuracy)
    end
end

model_comparison = DataFrame(
    model_name = repeat(name_model_list,number_runs),
    epoch_number = repeat(epoch_number_list,number_runs),
    mean_accuracy = accuracy_model
)

CSV.write("data/comparison_temporal autocorrelation.csv", model_comparison)