### Load model
include("01_Julia-RNN_model.jl")

### Import data
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame

function scenario_S2(frame::Int64, epochs::Int64)

    accuracy_model = []
    list_windows_start = []
    list_windows_end = []

    starting_row = 1
    ending_row = convert(Int64, starting_row + frame*2-1)

    max_row = nrow(diversity_data)

    while ending_row < max_row

        @info("Data from row $starting_row to $ending_row (maximum $max_row rows)")
        
        data_selected = diversity_data[starting_row:ending_row, :]

        append!(list_windows_start, starting_row)
        append!(list_windows_end, ending_row)

        ending_row = ending_row + 1

        starting_row = starting_row + 1
        
        idx = 1:frame*2

        model, output_model, all_accuracy, mean_accuracy, loss_model = forecast_model(
            data_selected, 
            epochs,
            "V6_best",
            0, #No prediction
            true,#using sorted data
            true, #force the use of a training and test dataset
            view(idx, 1:floor(Int, frame)), #Row to use for the training
            view(idx, (floor(Int, frame)+1):frame*2) #Rows to use for the test
            )
        @info ("Mean Accuracy = $mean_accuracy")
        append!(accuracy_model,mean_accuracy)

    end

    model_comparison = DataFrame(
        training_frame = string(frame),
        windows_start = list_windows_start,
        windows_end = list_windows_end,
        epoch_number = string(epochs),
        mean_accuracy = accuracy_model
    )

    CSV.write("data/results_scenario/S2[training_frame]/windows_$frame.csv", model_comparison)
end