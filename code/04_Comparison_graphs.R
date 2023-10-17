## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
require(ggrepel)
require(reshape2)
require(rstatix)
require(ggthemes)

### Loading RMSE databases
RMSE_V9 = read.csv(
    "data/results_scenario/S0[best_model_selection]/V9/Acc_60/RMSE_V9.csv"
) %>% rename("RMSE" = "IA_RMSE")
RMSE_V9$source = "RNN"

RMSE_SARIMA = read.csv(
    "data/SARIMA/RMSE_SARIMA.csv"
) %>% rename("RMSE"= "SARIMA_RMSE")
RMSE_SARIMA$source = "SARIMA"

RMSE_LOESS = read.csv(
    "data/LOESS/RMSE_LOESS.csv"
) %>% rename("RMSE" = "LOESS_RMSE")
RMSE_LOESS$source = "LOESS"

### Loading Accuracy databases
Acc_LOESS = read.csv(
    "data/LOESS/accuracy_LOESS.csv"
) %>% select(-acc_missing) %>% rename("accuracy" = "LOESS_accuracy")
Acc_LOESS$source = "LOESS"

Acc_V9 = read.csv(
    "data/results_scenario/S0[best_model_selection]/V9/Acc_60/modelV9_best_species_accuracy.csv"
) %>% rename("accuracy" = "model_accuracy")
Acc_V9$source = "RNN"

Acc_SARIMA = read.csv(
    "data/SARIMA/accuracy_SARIMA.csv"
)%>% select(-acc_missing) %>% rename("accuracy" = "SARIMA_accuracy")
Acc_SARIMA$source = "SARIMA"

### Loading Time series databases
# Output LOESS
res_LOESS = read.csv(
    "data/LOESS/output_LOESS.csv",
    sep = ";"
)
res_LOESS$data_source = "LOESS"
res_LOESS$type = "model"
res_LOESS = res_LOESS %>% filter(step > 7)

# Output IA
res_RNN = read.csv(
    "data/results_scenario/S0[best_model_selection]/V9/Acc_60/modelV9_best_output_model.csv"
)
res_RNN$data_source = "RNN"
res_RNN$type = "model"
res_RNN$step = as.numeric(rownames(res_RNN)) + 7

# Output SARIMA
res_SARIMA = read.csv(
    "data/SARIMA/output_SARIMA.csv",
    sep = ";"
)
res_SARIMA$data_source = "SARIMA"
res_SARIMA$type = "model"
res_SARIMA$step = as.numeric(rownames(res_SARIMA)) + 6
res_SARIMA = res_SARIMA %>% filter(step < 47)

# Real data
real_data = read.csv(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    sep = ";"
) %>% filter(step < 47) %>% select(-sampling_period)
real_data$data_source = "Real data"
real_data$type = "real_data"

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

#####
## Compare RMSE and Accuracy
#####
## Merge data
RMSE = rbind(
    RMSE_V9,
    RMSE_SARIMA,
    RMSE_LOESS
)
RMSE_plot = melt(
    RMSE,
    id.vars = c("MF", "source")
)

Acc = rbind(
    Acc_V9,
    Acc_SARIMA,
    Acc_LOESS
)
Acc_plot = melt(
    Acc,
    id.vars = c("source", "MF")
)
Acc_plot = Acc_plot %>% filter(!is.nan(Acc_plot$value))
Acc_plot$value = round(100*Acc_plot$value, 3)

Comp_data = rbind(Acc_plot, RMSE_plot)
Comp_data$variable = str_replace_all(Comp_data$variable, "accuracy", "Accuracy (%)")

## Boxplot RMSE
BoxPlot_RMSE = ggplot(
    data = Comp_data,
    aes(
        x = source,
        y = value
    )
) + 
geom_boxplot(
    color = "black",
    aes(
        fill = source
    )
) + scale_fill_manual(values = c("#3498db", "#e67e22", "#9b59b6")) +
theme_stata() + 
facet_wrap(.~variable, scales = "free_y") +
labs(
    x = element_blank(),
    y = element_blank()
) +
theme(legend.position = "none")

BoxPlot_RMSE

ggsave(
    "docs/comparison_modelling_approach/Comp_model.jpg",
    width = 10,
    height = 10,
    units = "in"
)


kruskal.test(RMSE$RMSE ~ RMSE$source)
kruskal.test(Acc$accuracy ~ Acc$source)

test_wilcox_RMSE = wilcox_test(
  data = RMSE,
  RMSE~source ,
  comparisons = NULL,
  ref.group = NULL,
  p.adjust.method = "holm",
  paired = FALSE,
  exact = NULL,
  alternative = "two.sided",
  mu = 0,
  conf.level = 0.95,
  detailed = FALSE
)

test_wilcox_Acc = wilcox_test(
  data = Acc,
  accuracy~source ,
  comparisons = NULL,
  ref.group = NULL,
  p.adjust.method = "holm",
  paired = FALSE,
  exact = NULL,
  alternative = "two.sided",
  mu = 0,
  conf.level = 0.95,
  detailed = FALSE
)

write.table(
    test_wilcox_RMSE,
   "docs/comparison_modelling_approach/Wilcox_RMSE.csv",
   sep = ";",
   row.names = F 
)

write.table(
    test_wilcox_Acc,
   "docs/comparison_modelling_approach/Wilcox_Acc.csv",
   sep = ";",
   row.names = F 
)


#####
## Compare time series
#####

### Merge data
data_plot = rbind(
    res_RNN,
    res_SARIMA,
    res_LOESS,
    real_data
)

### Melt data
data_plot = melt(
    data_plot,
    id.vars = c("step", "data_source", "type")
)

## Réordonnancement de data_plot$data_source
data_plot$data_source <- data_plot$data_source %>%
  fct_relevel(
    "Real data", "RNN", "SARIMA", "LOESS"
  )

## Add Scientific name
data_plot = merge(
    data_plot,
    MF_name,
    by.x = "variable",
    by.y = "MF"
)

### Plot
ggplot(
    data_plot,
    aes(
        x = step,
        y = value,
        color = data_source,
        shape = data_source
    )
)+ geom_point()+
geom_line(aes(group = data_source, linetype = type))+ 
scale_linetype_manual(values = c("dotted", "solid"))+
scale_color_manual(values = c("#1abc9c","#e67e22","#9b59b6","#3498db"))+
guides(linetype = FALSE) +
facet_wrap(
    .~scientificName,
    scales= "free_y",
    ncol = 4
) + geom_vline(
    xintercept = 30+7
) +
labs(
    x = "Season numbers",
    y = "Adult abundance",
    color = "Modelling approach",
    shape = "Modelling approach"
) + theme(
    legend.position = "bottom"
)+ theme_stata()+ theme(
    strip.text.x = ggtext::element_markdown(angle = 0),
    strip.background.x = element_rect(color = "black")
)

ggsave(
    "docs/comparison_modelling_approach/Comp_Model.jpg",
    width = 20,
    height = 40
)
