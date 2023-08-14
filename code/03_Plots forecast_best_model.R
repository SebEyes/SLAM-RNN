### Loading Packages
require(stringr)
require(dplyr)
require(tidyr)
require(reshape2)
require(ggplot2)

### Load data
# Output model
res_RNN = read.csv(
    "data/results_scenario/S0[best_model_selection]/modelV6_best_output_model.csv"
)
names(res_RNN) = str_remove_all(names(res_RNN), "X")
res_RNN$data_source = "model prediction"

# Real data
real_data = read.csv(
    "data/Matrix_dominant.csv",
    sep = ";"
)
names(real_data) = str_remove_all(names(real_data), "X")
real_data$data_source = "real data"

### Plot
data_plot = rbind(res_RNN, real_data)

data_plot$time_step = as.numeric(data_plot$time_step)

data_plot = melt(
    data_plot,
    id.vars = c("time_step", "data_source")
)

ggplot(
    #data_plot[data_plot$time_step > 34 & data_plot$time_step < 45,],
    data_plot,
    aes(
        x = time_step,
        y = value,
        color = data_source
    )
) + 
geom_line(aes(group = data_source)) + 
geom_point() + 
facet_wrap(
    .~variable,
    scales= "free_y"
)

# ggsave(
#     "docs/ModelV6_best_prediction.jpg",
#     width = 20,
#     height = 20
# )