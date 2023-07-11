### Environment gestion
using Pkg
Pkg.activate(".")
Pkg.instantiate()

## Package installation
# Pkg.add("Flux")
# Pkg.add("Statistics")
# Pkg.add("CSV")
# Pkg.add("DataFrames")
# Pkg.add("Plots")
# Pkg.add("ProgressMeter")
# Pkg.add("JLD2")
# Pkg.add("Distances")

## Loading Packages
using Flux, Statistics, Distances
using CSV, DataFrames
using Plots
using ProgressMeter
using Flux: train!
using JLD2

function forecast_model(
    dataset::DataFrame,
    epoch_number::Int,
    model_version::String,
    number_prediction::Int
)

    model_name = "RNN_$(model_version)"

    ### Define train and test dataset  
    function partitionTrainTest(data::DataFrame, at = 0.75)
        n = nrow(data)
        idx = 1:n
        train_idx = view(idx, 1:floor(Int, at*n))
        test_idx = view(idx, (floor(Int, at*n)+1):n)
        data[train_idx,:], data[test_idx,:]
    end

    train_data, test_data = partitionTrainTest(dataset);

    sort!(
        train_data,
        order(
            :time_step,
            rev = false
        )
    )

    sort!(
        test_data,
        order(
            :time_step,
            rev = false
        )
    )

    nsamples = nrow(train_data)

    in_features = 1

    out_features = ncol(train_data) - in_features

    x_train = permutedims(hcat(Matrix(train_data)[:,in_features + out_features]))
    x_test = permutedims(hcat(Matrix(test_data)[:,in_features + out_features]))

    y_train = permutedims(hcat(Matrix(train_data)[:,1:out_features]))

    data_train = Flux.Data.DataLoader((x_train,y_train))

    ## Model architecture
    Nnrns = trunc(Int, 2/3*(in_features + out_features)) #Number of neurons in the hidden layer
    
    model = Chain(
        LSTM(in_features, Nnrns),
        LSTM(Nnrns, Nnrns),
        Dense(Nnrns, out_features, relu),
        Dense(out_features, out_features, relu)
    )

    # Define a loss function(here: mean squared error)
    loss(x, y) = Flux.mse(model(x),y)

    # Keep track of parameters for update
    ps = Flux.params(model);
    trainingloss = [];

    # Choose an optimizer
    opt = Flux.ADAM()

    # Training
    @info("Beginning training loop for $(epoch_number) epochs")
    X1, Y1 = first(data_train)

    @showprogress for epoch in 1:epoch_number
        Flux.train!(loss,ps,data_train,opt)
        append!(trainingloss, loss(X1, Y1)) # Compute loss on the first data
    end

    @info("Training ended")
    plot(trainingloss)

    ## Saving model
    model_state = Flux.state(model)
    jldsave("code/model/$(model_name).jld2"; model_state)

    ### output
    time_step = vec([x_train x_test])
    time_step_prediction = last(time_step, number_prediction) .+ number_prediction
    time_step = vcat(time_step, time_step_prediction)
    
    prediction = []
    for value in time_step
        # println(value)
        value = [value]
        append!(prediction, model(value))
    end

    output = DataFrame(reshape(prediction,(out_features, size(time_step,1))),:auto)
    output = permutedims(output)
    output.time_step = vec(time_step)
    rename!(output, names(diversity_data))


    ### Accuracy computation (euclidean distance)
    accuracy = []
    for value in x_test
        value = [value]
        append!(accuracy, model(value))
    end

    accuracy_table = DataFrame(reshape(accuracy,(out_features,size(x_test,2))),:auto)
    accuracy_table = permutedims(accuracy_table)
    accuracy_table.time_step = vec(x_test)
    rename!(accuracy_table, names(diversity_data))
    sort!(accuracy_table, order(:time_step, rev = false))


    eucli_dist = []
    for col in 1:ncol(accuracy_table)
        append!(
            eucli_dist,
            euclidean(
                float.(accuracy_table[:,col]),
                float.(test_data[:,col])
            )
        )
    end

    accuracy_result = DataFrame(
        euclidian_distance = eucli_dist,
        MF = names(accuracy_table)
    )

    output, accuracy_result, mean(accuracy_result.euclidian_distance), trainingloss
end