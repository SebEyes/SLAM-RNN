# Create synthetic data first
### Function to generate x consisting of three variables and a sequence length of 200
function generateX()
    x1 = Array{Float32, 1}(randn(200))
    x2 = Array{Float32, 1}(randn(200))
    x3 = Array{Float32, 1}(sin.((0:199) / 12*2*pi))
    xdata=[x1 x2 x3]'
    return(xdata)
end

### Generate 50 of these sequences of x
xdata = [generateX() for i in 1:50]

### Function to generate sequence of y from x sequence
function yfromx(x)
    y=Array{Float32, 1}(0.2*cumsum(x[1,:].*x[2,:].*exp.(x[1,:])) .+x[3,:])
    return(y')
end
ydata =  map(yfromx, xdata);

### Now rearrange such that there is a sequence of 200 X inputs, i.e. an array of x vectors (and 50 of those sequences)
xdata=Flux.batch(xdata) 
xdata2 = [xdata[:,s,c] for s in 1:200, c in 1:50]
xdata= [xdata2[:,c] for c in 1:50]

### Same for y
ydata=Flux.batch(ydata)
ydata2 = [ydata[:,s,c] for s in 1:200, c in 1:50]
ydata= [ydata2[:,c] for c in 1:50]

### Define model and loss function. "model." returns sequence of y from sequence of x
import Base.Iterators: flatten
model=Chain(LSTM(3, 26), Dense(26,1))

loss(x,y) = Flux.mse(collect(flatten(model.(x))),collect(flatten(y)))

model.(xdata[1]) # works fine
loss(xdata[2],ydata[2]) # also works fine

Flux.train!(loss, params(model), zip(xdata, ydata), ADAM(0.005)) ## Does not work, see error below. How to work around?