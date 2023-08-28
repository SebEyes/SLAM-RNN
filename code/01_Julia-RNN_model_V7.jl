## Package installation
# Pkg.add("Flux")
# Pkg.add("Statistics")
# Pkg.add("CSV")
# Pkg.add("DataFrames")
# Pkg.add("Plots")
# Pkg.add("ProgressMeter")
# Pkg.add("Distances")
# Pkg.add("LinearAlgebra")
# Pkg.add("Shuffle")

## Loading Packages
using Flux, Statistics, Distances
using CSV, DataFrames
using Plots
using ProgressMeter
using Flux: train!
using LinearAlgebra
using Shuffle
using Distributed

### Parallel computing
if nprocs() < 3
    addprocs(2)
end
CPU_unit = nprocs()
@info("Using $CPU_unit CPU units")


### Define train and test dataset  
function partitionTrainTest(data::DataFrame, at = 0.75)
    n = nrow(data)
    idx = 1:n
    train_idx = view(idx, 1:floor(Int, at*n))
    test_idx = view(idx, (floor(Int, at*n)+1):n)
    @info("Using sorted time step")
    train_dataset = data[train_idx,:]
    test_dataset = data[test_idx,:]
    @info("Using $train_idx train data and $test_idx test data")
    train_dataset, test_dataset
end

function VIVALDAI_model(
    dataset::DataFrame,
    epoch_number::Int,
    number_prediction::Int
)
    #REduce precision to imrpove computation time
    dataset = convert.(Int16,dataset)

    train_data, test_data = partitionTrainTest(dataset)

    in_features = ncol(dataset) #number of species

    batch_size = 4 #4 seasons

    out_features = ncol(dataset) #number of species

    x_train = permutedims(Matrix(train_data))

    x_train = permutedims(hcat(Matrix(train_data)[:,in_features + out_features]))
    x_test = permutedims(hcat(Matrix(test_data)[:,in_features + out_features]))

    y_train = permutedims(hcat(Matrix(train_data)[:,1:out_features]))

    data_train = Flux.Data.DataLoader((x_train,y_train))

    ## Model architecture
    Nnrns = 100 #Number of neurons in the hidden layer
    
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
    # plot(trainingloss)

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


    accuracy_list = []
    for col in 1:ncol(accuracy_table)
        test_true = convert.(Float64, test_data[:,col])
        test_model = convert.(Float64, accuracy_table[:,col])
        scalar_product = dot(test_true, test_model)

        cos_angle = (scalar_product / (norm(test_true) * norm(test_model)))

        accuracy = cos_angle * (1-((abs(norm(test_model) - norm(test_true)))/((norm(test_model) + norm(test_true)))))
        
        if isnan(accuracy)
            accuracy = 0
        end

        append!(
            accuracy_list,
            accuracy
        )
    end

    accuracy_result = DataFrame(
        model_accuracy = accuracy_list,
        MF = names(accuracy_table)
    )

    model, output, accuracy_result, mean(accuracy_result.model_accuracy[1:38,:]), trainingloss
end