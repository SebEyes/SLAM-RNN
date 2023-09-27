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

### Define a function to format the input data for the model
function Input_format(input_data, yearly::Bool, out_features = 39)
    input_DataX = []
    input_DataY = []
    if yearly
        @info("Formatting yearly data")
        batch_size = 4
        for seasons in 1:size(input_data)[1]-batch_size
            append!(
                input_DataX,
                [input_data[seasons] ; input_data[seasons+1] ; input_data[seasons+2] ; input_data[seasons+3]]
            )
            append!(
                input_DataY,
                input_data[seasons+3]
            )
        end
    else
        @info("Formatting seasonnal data")
        batch_size = 1
        for seasons in 1:size(input_data)[1]-batch_size
            append!(
                input_DataX,
                input_data[seasons]
            )
            append!(
                input_DataY,
                input_data[seasons+1]
            )
        end
    end
    input_DataX = reshape(input_DataX, out_features*batch_size, size(input_data)[1]-batch_size)
    input_DataY = reshape(input_DataY, out_features, size(input_data)[1]-batch_size)
    input_DataX, input_DataY
end

### Accuracy computation
function Accuracy(model_data, real_data)
    scalar_product = dot(real_data, model_data)

    cos_angle = (scalar_product / (norm(real_data) * norm(model_data)))

    accuracy = cos_angle * (1-((abs(norm(model_data) - norm(real_data)))/((norm(model_data) + norm(real_data)))))
    
    # if isnan(accuracy)
    #     accuracy = missing
    # end
    accuracy
end

### Model V7
function VIVALDAI_model(
    dataset::DataFrame,
    epoch_number::Int,
    yearly::Bool)

    #Reduce precision to imrpove computation time
    dataset = convert.(Float32,dataset)

    train_data, test_data = partitionTrainTest(dataset)

    if yearly
        batch_size = 4
    else
        batch_size = 1
    end

    in_features = ncol(dataset) * batch_size #Number of seasons

    out_features = ncol(dataset) #number of species

    train_data = Matrix(train_data)
    train_data = [train_data[season,:] for season in 1:size(train_data)[1]]

    test_data = Matrix(test_data)
    test_data = [test_data[season,:] for season in 1:size(test_data)[1]]

    X_dataTrain, Y_dataTrain = Input_format(train_data, yearly)
    X_dataTrain = convert.(Float32, X_dataTrain)
    Y_dataTrain = convert.(Float32, Y_dataTrain)

    X_dataTest, Y_dataTest = Input_format(test_data, yearly)
    X_dataTest = convert.(Float32, X_dataTest)
    Y_dataTest = convert.(Float32, Y_dataTest)

    Y_dataTest = permutedims(Y_dataTest)
    Y_dataTest = DataFrame(Y_dataTest, :auto)
    rename!(Y_dataTest, names(dataset))


    data_train = Flux.Data.DataLoader((X_dataTrain, Y_dataTrain))

    ## Model architecture
    Nnrns = 100 #Number of neurons in the hidden layer
    
    model = Chain(
        GRU(in_features, Nnrns),
        GRU(Nnrns, Nnrns),
        Dense(Nnrns,Nnrns, relu),
        Dense(Nnrns, out_features, relu)
    )

    # Define a loss function(here: mean squared error)
    loss(x, y) = 1-Accuracy(model(x),y)

    # Keep track of parameters for update
    ps = Flux.params(model);
    trainingloss = [];

    # Choose an optimizer (Classic Gradient descent)
    opt = Flux.Descent()

    # Training
    @info("Beginning training loop for $(epoch_number) epochs")
    X1, Y1 = first(data_train)

    @showprogress for epoch in 1:epoch_number
        Flux.train!(
            loss, # Loss function
            ps, #parameters
            data_train, #training data
            opt # Optimiser
        )
        append!(trainingloss, loss(X1, Y1)) # Compute loss on the first data
        if loss(X1, Y1) < 0.0
            @info("Low loss, stopping the training loop (loss = $(loss(X1, Y1))) after $(epoch) epochs")
            break
        end
    end
    @info("Training ended")
    # using Plots
    # plot(abs.(trainingloss.-1))

    ### output
    Xdata = [train_data; test_data]

    prediction = model.(Xdata)
    output, _ = Input_format(prediction, false)

    output = DataFrame(output,:auto)
    output = permutedims(output)
    rename!(output, names(dataset))


    ### Accuracy computation
    accuracy_table = output[end-9:end,:] #Model output
    Y_dataTest = dataset[end-9:end,:] #Real data


    accuracy_list = []
    for col in 1:ncol(accuracy_table)
        test_true = convert.(Float64, Y_dataTest[:,col])
        test_model = convert.(Float64, accuracy_table[:,col])

        accuracy = Accuracy(test_model, test_true)

        append!(
            accuracy_list,
            accuracy
        )
    end

    accuracy_result = DataFrame(
        model_accuracy = accuracy_list,
        MF = names(accuracy_table)
    )
    accuracy_result.acc_missing = any.(i -> !isnan(i), accuracy_result.model_accuracy)

    acc_available = accuracy_result[any.(accuracy_result.acc_missing),:]
    mean_acc = mean(acc_available.model_accuracy)

    model, output, select!(accuracy_result, Not(:acc_missing)), mean_acc, trainingloss
end

# # Testing the model

# dataset = select(diversity_data, Not(:time_step))

# model, output, accuracy_result, mean_accuracy, trainingloss = VIVALDAI_model(
#     dataset, 
#     100_000, 
#     false
# )
# using BSON

# BSON.@save "data/results_scenario/S0[best_model_selection]/model_V7_VIVALDAI_60.bson" model
# CSV.write("data/results_scenario/S0[best_model_selection]/modelV7_output.csv", output)
# CSV.write("data/results_scenario/S0[best_model_selection]/modelV8_speciesAcc.csv", accuracy_result)

# # BSON.@load "data/results_scenario/S0[best_model_selection]/model_V7_VIVALDAI_60.bson" model

