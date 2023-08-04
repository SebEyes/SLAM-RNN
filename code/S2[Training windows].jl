### Load model
include("01_Julia-RNN_model.jl")

### Import data
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame

function scenario_S2(frame::Int64, epochs::Int64)
    epoch_number_list = [epochs, epochs]

    number_runs = nrows(diversity_data) / frame ### Ajouter floor

    accuracy_model = []

    for run in 1:number_runs
        @info("Run number $run/$number_runs")
        model, output_model, all_accuracy, mean_accuracy, loss_model = forecast_model(
            diversity_data, 
            epochs,
            "V6_best",
            0, #No prediction
            true #using sorted data
            )
        @info ("Mean Accuracy = $mean_accuracy")
        append!(accuracy_model,mean_accuracy)

    end

    model_comparison = DataFrame(
        model_name = repeat(name_model_list,number_runs),
        epoch_number = repeat(epoch_number_list,number_runs),
        mean_accuracy = accuracy_model
    )

    CSV.write("data/results_scenario/S1[temporal_autocorrelation]/comparison_temporal autocorrelation.csv", model_comparison)
end