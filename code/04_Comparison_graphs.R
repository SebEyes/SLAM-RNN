## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
require(ggrepel)
require(reshape2)
require(rstatix)

### Loading RMSE databases
RMSE_V9 = read.csv(
    "data/results_scenario/S0[best_model_selection]/V9/Acc_50/RMSE_V9.csv"
) %>% rename("RMSE" = "IA_RMSE")
RMSE_V9$source = "IA"

RMSE_SARIMA = read.csv(
    "data/SARIMA/RMSE_SARIMA.csv"
) %>% rename("RMSE"= "SARIMA_RMSE")
RMSE_SARIMA$source = "SARIMA"

RMSE_LOESS = read.csv(
    "data/LOESS/RMSE_LOESS.csv"
) %>% rename("RMSE" = "LOESS_RMSE")
RMSE_LOESS$source = "LOESS"

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
    "data/results_scenario/S0[best_model_selection]/V9/Acc_50/modelV9_best_output_model.csv"
)
res_RNN$data_source = "IA"
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


#####
## Compare RMSE
#####
## Merge data
RMSE = rbind(
    RMSE_V9,
    RMSE_SARIMA,
    RMSE_LOESS
)

## Boxplot RMSE
BoxPlot_RMSE = ggplot(
    data = RMSE,
    aes(
        x = source,
        y = RMSE
    )
) + 
geom_boxplot() + 
labs(
    x = "Source",
    y = "RMSE"
) 

kruskal.test(RMSE$RMSE ~ RMSE$source)
test_wilcox = wilcox_test(
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

write.table(
    test_wilcox,
   "docs/comparison_modelling_approach/Wilcox_RMSE.csv",
   sep = ";",
   row.names = F 
)
BoxPlot_RMSE


ggsave(
    "docs/comparison_modelling_approach/Comp_RMSE.jpg",
    width = 4,
    height = 5,
    units = "in"
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
    "Real data", "IA", "SARIMA", "LOESS"
  )

### Plot
ggplot(
    data_plot,
    aes(
        x = step,
        y = value,
        color = data_source
    )
)+ geom_point()+
geom_line(aes(group = data_source, linetype = type))+ 
scale_linetype_manual(values = c("dotted", "solid"))+
guides(linetype = FALSE) +
facet_wrap(
    # nrow = length(unique(data_plot$variable)),
    .~variable,
    scales= "free_y"
) + geom_vline(
    xintercept = 37
) +
labs(
    x = "Season numbers",
    y = "Species abundance",
    color = "Modelling approach:"
) + theme(
    legend.position = "bottom"
)

ggsave(
    "docs/comparison_modelling_approach/Comp_TestData.jpg",
    width = 20,
    height = 20
)