### Load model
include("01_Julia-RNN_model.jl")

### Packages
using BSON

####
## This script allow to save the model with the best accuracy after trainings of the V6
####

### Import data
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame

function scenario_S0(number_runs::Int64, epochs::Int64)
    accuracy_model = [0.0]

    for run in 1:number_runs
        @info("Run number $run/$number_runs")
        model, output_model, all_accuracy, mean_accuracy, loss_model = forecast_model(
            diversity_data, 
            epochs,
            "V6_best",
            0, #No prediction
            true, #using sorted data
            false,
            0,
            0 #Use normal splitting of data for training and test
            )
        @info ("Mean Accuracy = $mean_accuracy")
        

        if mean_accuracy > maximum(accuracy_model) #if the new model has a better accuracy
        ## Saving model
            BSON.@save "data/results_scenario/S0[best_model_selection]/output_V6_best.bson" model

            # model_state = Flux.state(model)
            # jldsave("data/results_scenario/S0[best_model_selection]/test_saving.jld2"; model_state)
            
        ## Saving species accuracy
            CSV.write("data/results_scenario/S0[best_model_selection]/modelV6_best_species_accuracy.csv", all_accuracy)
        
        ## Saving output_model
            CSV.write("data/results_scenario/S0[best_model_selection]/modelV6_best_output_model.csv", output_model)

            @info ("Saving Model")
        end

        append!(accuracy_model, mean_accuracy)
    end

    model_selection = DataFrame(
        run = 0:number_runs,
        mean_accuracy = accuracy_model
    )

    CSV.write("data/results_scenario/S0[best_model_selection]/modelV6 selection.csv", model_selection)
    
end