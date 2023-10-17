## Package
require(stringr)
require(tidyr)
require(dplyr)
require(reshape2)
require(rstatix)

### Loading RMSE databases
RMSE_V9 = read.csv(
    "data/results_scenario/S0[best_model_selection]/V9/Acc_60/RMSE_V9.csv"
) %>% rename("RNN_RMSE" = "IA_RMSE")

RMSE_SARIMA = read.csv(
    "data/SARIMA/RMSE_SARIMA.csv"
)

RMSE_LOESS = read.csv(
    "data/LOESS/RMSE_LOESS.csv"
)

### Loading accuracy databases
Acc_V9 = read.csv(
    "data/results_scenario/S0[best_model_selection]/V9/Acc_60/modelV9_best_species_accuracy.csv"
) %>% rename("RNN_Acc" = "model_accuracy")

Acc_SARIMA = read.csv(
    "data/SARIMA/accuracy_SARIMA.csv"
) %>% select(-acc_missing)

Acc_LOESS = read.csv(
    "data/LOESS/accuracy_LOESS.csv"
) %>% select(-acc_missing)

### MF list
MF_list = read.csv(
    "data/diversity_data/SuppS2_MF_Info.csv",
    sep = ";"
)
MF_list$MF = paste("MF", MF_list$MF, sep = "")
MF_name = select(
    MF_list,
    MF,
    scientificName
)

## Merging
Comparison_table = merge(
    RMSE_V9,
    RMSE_LOESS,
    by = "MF",
    all = T
)
Comparison_table = merge(
    Comparison_table,
    RMSE_SARIMA,
    by = "MF",
    all = T
)

Comparison_table = merge(
    Comparison_table,
    Acc_V9,
    by = "MF",
    all = T
)

Comparison_table = merge(
    Comparison_table,
    Acc_LOESS,
    by = "MF",
    all = T
)

Comparison_table = merge(
    Comparison_table,
    Acc_SARIMA,
    by = "MF",
    all = T
)

Comparison_table = merge(
    Comparison_table,
    MF_name,
    by = "MF",
    all = T
)

Comparison_table = Comparison_table %>% arrange(scientificName)

write.table(
    Comparison_table,
    "docs/comparison_modelling_approach/Comp_error.csv",
    sep = ";",
    row.names = F
)
