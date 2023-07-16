### Load model
include("01_Julia-RNN_model.jl")

####
## This script allow to save the model with the best accuracy after 20 trainings of the V6
## Require between 12 to 24 hours to run
####

### Import data
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame


number_runs = 20

accuracy_model = []

for run in 1:number_runs
    @info("Run number $run/$number_runs")
    model, output_model, all_accuracy, mean_accuracy, loss_model = forecast_model(
        diversity_data, 
        50_000, #between 30-60 of computation
        "V6_best",
        0, #No prediction
        true #using sorted data
        )
    @info ("Mean Accuracy = $mean_accuracy")
    append!(accuracy_model, mean_accuracy)

    if mean_accuracy > last(accuracy_model) #if the new model has a better accuracy than the last one
    ## Saving model
        model_state = Flux.state(model)
        jldsave("code/model/V6_best.jld2"; model_state)
    end
end

model_selection = DataFrame(
    run = 1:number_runs,
    mean_accuracy = accuracy_model
)

CSV.write("data/modelV6 selection.csv", model_selection)