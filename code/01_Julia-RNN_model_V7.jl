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

### Define a function to format the input data for the model
function Input_format(input_data)
    input_DataX = []
    input_DataY = []
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
    input_DataX = reshape(input_DataX, in_features, size(input_data)[1]-batch_size)
    input_DataY = reshape(input_DataY, out_features, size(input_data)[1]-batch_size)
    input_DataX, input_DataY
end

### Model V7
function VIVALDAI_model(
    dataset::DataFrame,
    epoch_number::Int
)
    #Reduce precision to imrpove computation time
    dataset = convert.(Int16,dataset)

    train_data, test_data = partitionTrainTest(dataset)

    batch_size = 4 #4 seasons

    in_features = ncol(dataset) * batch_size #Flattened vector of 38 species over 4 seasons

    out_features = ncol(dataset) #number of species

    train_data = Matrix(train_data)
    train_data = [train_data[season,:] for season in 1:size(train_data)[1]]

    test_data = Matrix(test_data)
    test_data = [test_data[season,:] for season in 1:size(test_data)[1]]

    X_dataTrain, Y_dataTrain = Input_format(train_data)
    X_dataTrain = convert.(Int16, X_dataTrain)
    Y_dataTrain = convert.(Int16, Y_dataTrain)

    X_dataTest, Y_dataTest = Input_format(test_data)
    X_dataTest = convert.(Int16, X_dataTest)
    Y_dataTest = convert.(Int16, Y_dataTest)

    Y_dataTest = permutedims(Y_dataTest)
    Y_dataTest = DataFrame(Y_dataTest, :auto)
    rename!(Y_dataTest, names(dataset))


    data_train = Flux.Data.DataLoader((X_dataTrain, Y_dataTrain))

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
        Flux.train!(
            loss, # Loss function
            ps, #parameters
            data_train, #training data
            opt # Optimiser
        )
        # append!(trainingloss, loss(model_out, true_value)) # Compute loss on the first data
    end
    @info("Training ended")
    # plot(trainingloss)

    ### output
    prediction = []
    for four_seasons in 1:size(X_dataTrain)[2]
        # println(value)
        year_data = X_dataTrain[:,four_seasons]
        append!(prediction, model(year_data))
    end

    output = reshape(prediction, (out_features, size(X_dataTrain)[2]))

    output = DataFrame(output,:auto)
    output = permutedims(output)
    rename!(output, names(dataset))


    ### Accuracy computation
    accuracy = []
    for four_seasons in 1:size(X_dataTest)[2]
        year_data = X_dataTrain[:,four_seasons]
        append!(accuracy, model(year_data))
    end

    accuracy_table = reshape(accuracy, (out_features, size(X_dataTest)[2]))

    accuracy_table = DataFrame(accuracy_table,:auto)
    accuracy_table = permutedims(accuracy_table)
    rename!(accuracy_table, names(dataset))


    accuracy_list = []
    for col in 1:ncol(accuracy_table)
        test_true = convert.(Float64, Y_dataTest[:,col])
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