### Load model
include("/home/sebastien/Documents/GBA/SLAM-RNN/code/IA_model/01_Julia-RNN_model_V8.jl")

### Packages
using BSON, Plots

####
## This script allow to save the model with the best accuracy after trainings of the V6
####

### Import data
diversity_data = CSV.File(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    delim = ";"
) |> DataFrame
select!(diversity_data, Not(:step))
select!(diversity_data, Not(:sampling_period))

function scenario_S0(number_runs::Int64, epochs::Int64)
    accuracy_model = [0.0]

    for run in 1:number_runs
        @info("Run number $run/$number_runs")
        model, output_model, all_accuracy, mean_accuracy, loss_model = VIVALDAI_model(
            diversity_data, 
            100_000,
            false
        )
        @info ("Mean Accuracy = $mean_accuracy")
        

        if mean_accuracy > maximum(accuracy_model) #if the new model has a better accuracy
        ## Saving model
            BSON.@save "data/results_scenario/S0[best_model_selection]/output_V9_54%.bson" model

            # model_state = Flux.state(model)
            # jldsave("data/results_scenario/S0[best_model_selection]/test_saving.jld2"; model_state)
            
        ## Saving species accuracy
            CSV.write("data/results_scenario/S0[best_model_selection]/modelV9_best_species_accuracy.csv", all_accuracy)
        
        ## Saving output_model
            CSV.write("data/results_scenario/S0[best_model_selection]/modelV9_best_output_model.csv", output_model)
        
        ## Plot Loss
            plot(loss_model)
            loss_model = Float32.(loss_model)

            table_loss = DataFrame(
                value = loss_model
            )
            CSV.write("data/results_scenario/S0[best_model_selection]/modelV9_best_loss_model.csv", table_loss)


            @info ("Saving Model")
        end

        append!(accuracy_model, mean_accuracy)
    end

    model_selection = DataFrame(
        run = 0:number_runs,
        mean_accuracy = accuracy_model
    )

    CSV.write("data/results_scenario/S0[best_model_selection]/modelV8 selection.csv", model_selection)
    
end