### Load model
include("01_Julia-RNN_model.jl")

### Import data
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ","
) |> DataFrame

## Remove MF 116 and 19
diversity_data = select(
    diversity_data, 
    Not([:2, :16])
)

name_model_list = ["V5_20000", "V5_30000", "V5_40000", "V5_50000", "V5_100000"]
epoch_number_list = [20000, 30000, 40000, 50000, 100000]

accuracy_model = []

@showprogress for model_number in 1:size(name_model_list, 1)
    model_version = name_model_list[model_number]
    epoch_number = epoch_number_list[model_number]

    output_model, all_accuracy, mean_accuracy, loss_model = forecast_model(
    diversity_data, 
    epoch_number,
    model_version,
    8
    )
    @info ("Mean euclidean distance = $mean_accuracy")
    append!(accuracy_model,mean_accuracy)

    CSV.write("data/result_model_$(model_version).csv", output_model)
end

model_comparison = DataFrame(
    model_name = name_model_list,
    epoch_number = epoch_number_list,
    mean_euclidean_distance = accuracy_model
)

CSV.write("data/comparison_model.csv", model_comparison)