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

## Loading Packages
using Flux, Statistics
using CSV, DataFrames
using Plots
using ProgressMeter
using Flux: train!
using JLD2

### Import data
diversity_data = CSV.File(
    "data/Matrix_dominant.csv",
    delim = ";"
) |> DataFrame

## Remove MF 116 and 19
diversity_data = select(
    diversity_data, 
    Not([:2, :16])
)

### Define train and test dataset
# nsamples = 41; in_features = 1; out_features = 38;
train_data  = diversity_data

x_train = permutedims(hcat(Matrix(train_data)[:,39]))

y_train = permutedims(hcat(Matrix(train_data)[:,1:38]))

data_train = Flux.Data.DataLoader((x_train,y_train))


X1, Y1 = first(data_train) 
@show size(X1) size(Y1)

## Model architecture
Nx = size(X1, 1) #Number of input
Ny = size(Y1, 1) #Number of output
Nnrns = trunc(Int, 2/3*(Nx+Ny)) #Number of neurons in the hidden layer
model = Chain(
    LSTM(Nx, Nnrns),
    LSTM(Nnrns, Nnrns),
    Dense(Nnrns, Ny, relu),
    Dense(Ny, Ny, relu)
)

# Define a loss function(here: mean squared error)
loss(x, y) = Flux.mse(model(x),y)

# Keep track of parameters for update
ps = Flux.params(model);
trainingloss = [];

# Choose an optimizer
opt = Flux.ADAM()

# Number of training loop
epoch_number = 1_000_000;

# Training
@info("Beginning training loop for $(epoch_number) epochs")

@showprogress for epoch in 1:epoch_number
    Flux.train!(loss,ps,data_train,opt)
    append!(trainingloss, loss(X1, Y1))
end

@info("Training ended")
plot(trainingloss)

## Saving model
model_state = Flux.state(model)
jldsave("code/model/RNN_V5.jld2"; model_state)


### output
prediction = []
for value in 1:55
    value = [value]
    #println(value)
    append!(prediction, model(value))
end
output = DataFrame(reshape(prediction,(38,55)),:auto)

CSV.write("data/result_RNN_V5.csv", output)