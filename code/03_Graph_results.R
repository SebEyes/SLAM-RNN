## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
require(ggrepel)
require(reshape2)
require(forcats)
require(ggthemes)
require(ggtext)


#####
## Species accuracy (vector based) model VivaldAI
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
# Real data
real_data = read.csv(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    sep = ";"
)
names(real_data) = str_remove_all(names(real_data), "X")
real_data$data_source = "Real data"
real_data$forecasting = FALSE

# Output model
res_RNN = read.csv(
    "data/results_scenario/S0[best_model_selection]/V9/Acc_60/modelV9_best_output_model.csv"
)
names(res_RNN) = str_remove_all(names(res_RNN), "X")
res_RNN$data_source = "Model V9"
res_RNN$forecasting = FALSE
start_step = min(real_data$step)+1
end_step = max(real_data$step)
res_RNN$step = as.numeric(start_step:end_step)

# Forecasted data
# forecast = read.csv(
#     "data/forecast best modelV7/forecasted_data.csv"
# )
# names(forecast) = str_remove_all(names(forecast), "X")
# forecast$data_source = "Forecast"
# forecast$forecasting = TRUE
# forecast$time_step = c((max(res_RNN$time_step)+1):(max(res_RNN$time_step)+nrow(forecast)))

# MF list
MF_list = read.csv(
    "data/diversity_data/SuppS2_MF_Info.csv",
    sep = ";"
)
MF_list$MF = paste("MF", MF_list$MF, sep = "")
MF_name = select(
    MF_list,
    MF,
    genus,
    specificEpithet,
    infraspecificEpithet,
    scientificNameAuthorship,
    scientificName
)

MF_name$scientificName = paste(
    "*",
    MF_name$genus,
    " ",
    MF_name$specificEpithet,
    " ",
    MF_name$infraspecificEpithet,
    "*<br>",
    MF_name$scientificNameAuthorship,
    sep = ""
)
MF_name$scientificName = str_remove_all(
    MF_name$scientificName,
    " NA*"
)

# Accuracy species
Acc_sp = read.csv(
    "data/results_scenario/S0[best_model_selection]/V9/Acc_60/modelV9_best_species_accuracy.csv"
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


# Save step information
season_number = select(real_data, step, sampling_period)
real_data = real_data %>% select(-sampling_period)

### Plot
data_plot = rbind(res_RNN, real_data)

data_plot = melt(
    data_plot,
    id.vars = c("step", "data_source", "forecasting")
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
data_plot = merge(
    data_plot,
    MF_name,
    by.x = "variable",
    by.y = "MF"
)


data_plot$label = paste(
    data_plot$scientificName,
    "<br>**",
    data_plot$rounded,
    " %**",
    sep = ""
)

data_plot$label = str_replace_all(data_plot$label, "NaN %", "No fitting")
# data_plot$label = factor(data_plot$label,ordered = is.ordered(data_plot$rounded))

## Réordonnancement de data_plot$data_source
data_plot$data_source <- factor(data_plot$data_source,
  levels = c("Real data", "Model V9")
)

# Plot function
plot_time_series <- function(data_plot, show_acc = TRUE, limit_1 = TRUE, limit_2 = TRUE, save=FALSE, file_name=NA_character_) {
   plot_TS = ggplot(
    data_plot,
    aes(
        x = step,
        y = value,
        color = data_source
    )
    ) + 
    geom_line(aes(group = data_source, linetype= forecasting) )+ guides(linetype = FALSE) +
    geom_point()  + 
    theme(
        legend.position = "bottom",
        legend.box = "vertical"
    ) + theme_stata(
        base_size = 11
    )

    if (limit_1) {
       plot_TS = plot_TS + geom_vline(xintercept = as.numeric(max(real_data$step)- 10))
    }

    if (limit_2) {
       plot_TS = plot_TS + geom_vline(xintercept = min(forecast$step))
    }

    if (show_acc) {
       plot_TS = plot_TS +
       facet_wrap(
            # nrow = length(unique(data_plot$variable)),
            .~ label,
            scales= "free_y",
            ncol = 4
        ) + labs(
            x = "Seasons number",
            y = "Adult abundance",
            color = "Data source:"
        ) + theme(
            strip.text.x = ggtext::element_markdown(angle = 0),
            strip.background.x = element_rect(color = "black")
        )
    }else {
       plot_TS = plot_TS +
       facet_wrap(
            # nrow = length(unique(data_plot$variable)),
            .~variable,
            scales = "free_y"
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


#Full time series (raw results)
plot_time_series(
    data_plot, 
    save = TRUE,
    limit_2 = FALSE,
    file_name = "Model_V9-60"
)

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


#####
## Forecasts SARIMA
#####

### Load data
# Output SARIMA
SARIMA_fitting = read.csv(
    "data/SARIMA/output_SARIMA.csv",
    sep = ";"
)
SARIMA_fitting$data_source = "SARIMA"

# Real data
real_data = read.csv(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    sep = ";"
)
real_data$data_source = "Real data"
real_data = select(real_data, -sampling_period)

# Accuracy species
Acc_sp = read.csv(
    "data/SARIMA/accuracy_SARIMA.csv"
)
Acc_sp$rounded = round(Acc_sp$SARIMA_accuracy, 3)
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
data_plot = rbind(SARIMA_fitting, real_data)

data_plot = melt(
    data_plot,
    id.vars = c("step", "data_source")
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
  levels = c("Real data", "SARIMA")
)

# Plot function
plot_TS = ggplot(
    data_plot,
    aes(
        x = step,
        y = value,
        color = data_source
    )
    ) + 
    geom_line(aes(group = data_source, linetype= data_source) )+ guides(linetype = FALSE) +
    geom_point()  + 
    theme(
        legend.position = "bottom",
        legend.box = "vertical"
    ) + geom_vline(xintercept = 26 + 9) +
       facet_wrap(
            .~label,
            scales= "free_y")
plot_TS

ggsave("docs/graphs_SARIMA/SARIMA.jpg", plot_TS, width = 20, height = 20)


#####
## Forecasts LOESS
#####

### Load data
# Output LOESS
LOESS_fitting = read.csv(
    "data/LOESS/output_LOESS.csv",
    sep = ";"
)
LOESS_fitting$data_source = "LOESS"

# Real data
real_data = read.csv(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    sep = ";"
)
real_data$data_source = "Real data"
real_data = select(real_data, -sampling_period)

# Accuracy species
Acc_sp = read.csv(
    "data/LOESS/accuracy_LOESS.csv"
)
Acc_sp$rounded = round(Acc_sp$LOESS_accuracy, 3)
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
data_plot = rbind(LOESS_fitting, real_data)

data_plot = melt(
    data_plot,
    id.vars = c("step", "data_source")
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
  levels = c("Real data", "LOESS")
)

# Plot function
plot_TS = ggplot(
    data_plot,
    aes(
        x = step,
        y = value,
        color = data_source
    )
    ) + 
    geom_line(aes(group = data_source, linetype= data_source) )+ guides(linetype = FALSE) +
    geom_point()  + 
    theme(
        legend.position = "bottom",
        legend.box = "vertical"
    ) + geom_vline(xintercept = 26 + 9) +
       facet_wrap(
            .~label,
            scales= "free_y")
plot_TS

ggsave("docs/graphs_LOESS/LOESS.jpg", plot_TS, width = 20, height = 20)