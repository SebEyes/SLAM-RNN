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

#####
## Species accuracy
#####
Acc_sp = read.csv(
    "data/results_scenario/S0[best_model_selection]/modelV7_speciesAcc.csv"
)
Acc_sp$rounded = round(Acc_sp$model_accuracy, 3)
Acc_sp$rounded = Acc_sp$rounded * 100

ggplot(
    Acc_sp,
    aes(y = rounded)
) + geom_histogram(color = "black",
    bins = 15
) + labs(
    y = "Accuracy (%)",
    x = "Number of species"
) + geom_boxplot(
    fill = "darkgreen"
) 

ggsave("docs/species_accuracy_V7.jpg")

#####
## Forecasts model VivaldAI
#####

### Load data
# Output model
res_RNN = read.csv(
    "data/results_scenario/S0[best_model_selection]/modelV7_output.csv"
)
names(res_RNN) = str_remove_all(names(res_RNN), "X")
res_RNN$data_source = "Model prediction (test data)"
res_RNN$forecasting = FALSE
res_RNN$time_step = as.numeric(rownames(res_RNN))+1

# Forecasted data
forecast = read.csv(
    "data/forecast best modelV7/forecasted_data.csv"
)
names(forecast) = str_remove_all(names(forecast), "X")
forecast$data_source = "Forecast"
forecast$forecasting = TRUE
forecast$time_step = c((max(res_RNN$time_step)+1):(max(res_RNN$time_step)+nrow(forecast)))

# Real data
real_data = read.csv(
    "data/Matrix_dominant.csv",
    sep = ";"
)
names(real_data) = str_remove_all(names(real_data), "X")
real_data$data_source = "Real data"
real_data$forecasting = FALSE
real_data$time_step = as.numeric(rownames(real_data))

# Accuracy species
Acc_sp = read.csv(
    "data/results_scenario/S0[best_model_selection]/modelV7_speciesAcc.csv"
)
Acc_sp$rounded = round(Acc_sp$model_accuracy, 3)
Acc_sp$rounded = Acc_sp$rounded * 100

# Classifying quality
bad_limit = as.numeric(summary(Acc_sp$rounded)[2]) #1st quartile
medium_limit = as.numeric(summary(Acc_sp$rounded)[3]) #median
good_limit = as.numeric(summary(Acc_sp$rounded)[5]) #3rd quartile

Acc_sp$quality = "Excellent"
Acc_sp$quality[Acc_sp$rounded <= good_limit] = "Good"
Acc_sp$quality[Acc_sp$rounded <= medium_limit] = "Medium"
Acc_sp$quality[Acc_sp$rounded <= bad_limit] = "Bad"


### Plot
data_plot = rbind(res_RNN, real_data, forecast)

data_plot = melt(
    data_plot,
    id.vars = c("time_step", "data_source", "forecasting")
)
data_plot = merge(
    data_plot,
    select(
        Acc_sp,
        MF, rounded, quality
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

)## Réordonnancement de data_plot$data_source
data_plot$data_source <- factor(data_plot$data_source,
  levels = c("Real data", "Model prediction (test data)", "Forecast")
)

# Plot function
plot_time_series <- function(data_plot, show_acc = TRUE, limit_1 = TRUE, limit_2 = TRUE, save=FALSE, file_name=NA_character_) {
   plot_TS = ggplot(
    data_plot,
    aes(
        x = time_step,
        y = value,
        color = data_source
    )
    ) + 
    geom_line(aes(group = data_source, linetype= forecasting) )+ guides(linetype = FALSE) +
    geom_point()  + 
    theme(
        legend.position = "bottom",
        legend.box = "vertical"
    )

    if (limit_1) {
       plot_TS = plot_TS + geom_vline(xintercept = 26)
    }

    if (limit_2) {
       plot_TS = plot_TS + geom_vline(xintercept = min(forecast$time_step))
    }

    if (show_acc) {
       plot_TS = plot_TS +
       facet_wrap(
            nrow = length(unique(data_plot$variable)),
            .~label,
            scales= "free_y"
        ) + labs(
            x = "Seasons",
            y = "Abundance",
            color = "Data source:"
        )
    }else {
       plot_TS = plot_TS +
       facet_wrap(
            # nrow = length(unique(data_plot$variable)),
            .~variable,
            scales= "free_y"
        ) + labs(
            x = "Seasons",
            y = "Abundance",
            color = "Data source:"
        )
    }

    if (save) {
        ggsave(
        paste(
            "docs/",
            file_name,
            ".jpg",
            sep = ""
        ),
        width = 20,
        height = 20
        )
    }
}

#Raw data Train
plot_time_series(
    subset(data_plot, data_source == "Real data" & time_step < 27),
    save = TRUE,
    show_acc = FALSE,
    file_name = "Data_TimeSeries",
    limit_1 = FALSE,
    limit_2 = FALSE
)

#training and test raw data
plot_time_series(
    subset(data_plot, data_source == "Real data" & forecasting == FALSE),
    save = TRUE,
    show_acc = FALSE,
    file_name = "Data_TimeSeries_TrainTest",
    limit_1 = TRUE,
    limit_2 = FALSE
)

#Full time series (raw results)
plot_time_series(
    data_plot, 
    save = TRUE, 
    file_name = "Model_V7"
)

#Training data model and raw
plot_time_series(
    subset(data_plot, time_step < 27), 
    limit_2 = FALSE, 
    limit_1 = FALSE, 
    save = TRUE, 
    file_name = "Model_V7_Training"
)

# Test data
plot_time_series(
    subset(data_plot, (time_step >= 27 & forecasting == FALSE)), 
    limit_2 = FALSE, 
    limit_1 = FALSE, 
    save = TRUE, 
    file_name = "Model_V7_Test"
)

# Forecast data
plot_time_series(
    subset(data_plot, (time_step >= min(forecast$time_step) & forecasting == TRUE)), 
    limit_2 = FALSE, 
    limit_1 = FALSE, 
    save = TRUE, 
    file_name = "Model_V7_Forecast"
)

# Excellent fitting
plot_time_series(
    subset(data_plot, quality == "Excellent"), 
    limit_2 = TRUE, 
    limit_1 = TRUE, 
    save = TRUE, 
    file_name = "Model_V7_Excellent"
)