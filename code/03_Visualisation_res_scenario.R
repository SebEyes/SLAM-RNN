## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
require(ggrepel)
require(reshape2)

#####
## Mean accuracy model V6 with 50_000 epochs training (output S0)
#####

## Database
acc_model = read.csv(
    "data/results_scenario/S0[best_model_selection]/modelV6 selection.csv"
)
# remove run 0
acc_model = acc_model %>% filter(run > 0)

acc_model$mean_accuracy = acc_model$mean_accuracy * 100

## Boxplot mean accuracy
BoxPlot_accurracy = ggplot(
    data = acc_model,
    aes(
        x = "Accuracy model V6",
        y = mean_accuracy
    )
) + 
geom_boxplot() +
scale_y_continuous(limits = c(0,100)) + 
geom_text_repel(
    data = subset(acc_model, acc_model$mean_accuracy == max(acc_model$mean_accuracy)),
    aes(
        label = paste(
            "Best model (",
            round(max(acc_model$mean_accuracy),1),
            "%)",
            sep = ""
            )
    ),
    size = 5,
    box.padding = unit(-7, "lines")
)+ 
labs(
    x = "",
    y = "Mean accuracy (%)"
) 

BoxPlot_accurracy

# ggsave(
#     "docs/Accuracy_Model_V6.jpg",
#     width = 4,
#     height = 5,
#     units = "in"
# )

## Dispersion statistics
summary(acc_model$mean_accuracy)

#####
## Forecasts model V6 with 50_000 epochs training (output S0)
#####

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

# Accuracy species
Acc_sp = read.csv(
    "data/results_scenario/S0[best_model_selection]/modelV6_best_species_accuracy.csv"
)
Acc_sp$rounded = round(Acc_sp$model_accuracy, 3)
Acc_sp$rounded = Acc_sp$rounded * 100

### Plot
data_plot = rbind(res_RNN, real_data)

data_plot$time_step = as.numeric(data_plot$time_step)

data_plot = melt(
    data_plot,
    id.vars = c("time_step", "data_source")
)
data_plot = merge(
    data_plot,
    select(
        Acc_sp,
        MF, rounded
    ),
    by.x = "variable",
    by.y = "MF"
)

data_plot$label = paste(
    data_plot$variable,
    " (",
    data_plot$rounded,
    "%)",
    sep = ""
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
    .~label,
    scales= "free_y"
) + labs(
    x = "Time step",
    y = "Abundance",
    color = "Data source:"
)

# ggsave(
#     "docs/ModelV6_best_prediction.jpg",
#     width = 20,
#     height = 20
# )

#####
## Comparative accurracy model V6 with 50_000 epochs training (output S1)
#####

### Load data
# Accuracy tables
comp_acc = read.csv(
    "data/results_scenario/S1[temporal_autocorrelation]/comparison_temporal autocorrelation.csv"
)
comp_acc$mean_accuracy = 100*comp_acc$mean_accuracy
ggplot(
    data = comp_acc,
    aes(
        x = model_name,
        y = mean_accuracy,
        fill = model_name
    )
) + 
scale_y_continuous(
    limits = c(0, 100)
)+
geom_boxplot() +
theme(
    axis.text.x = element_blank(),
    axis.title.x = element_blank()
)+
labs(
    y = "Mean accurracy (%)",
    fill = "Model type:"
)
