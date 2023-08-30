Xtrain = rand(10, 100)
train_loader = Flux.Data.DataLoader(Xtrain, batchsize=2) 
# iterate over 50 mini-batches of size 2
for x in train_loader 
    @assert size(x) == (10, 2)
end

train_loader.data   # original dataset

Xtrain = rand(10, 100)
Ytrain = rand(100)
train_loader = Flux.Data.DataLoader((Xtrain, Ytrain), batchsize=2, shuffle=true) 
for epoch in 1:100
    for (x, y) in train_loader: 
        @assert size(x) == (10, 2)
        @assert size(y) == (2,)
        ...
    end
end

# train for 10 epochs
using IterTools: ncycle 
model = Dense(100=>100)
Flux.train!(loss, ps, ncycle(train_loader, 10), opt)

seq = [convert.(Float32,rand(5)) for i = 1:10] #10 vecteurs de 5 éléments
m = RNN(5, 10)
m.(seq)