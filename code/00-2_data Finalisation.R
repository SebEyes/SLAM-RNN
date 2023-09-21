## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
require(ggrepel)
require(reshape2)
require(forcats)

### Import database
total_DB = read.csv(
    "data/diversity_data/Matrix_Total_dominant.csv",
    sep = ";"
)
names(total_DB) = str_replace_all(names(total_DB), "X", "MF")

adult_DB = read.csv(
    "data/diversity_data/Matrix_Adults_dominant.csv",
    sep = ";"
)
names(adult_DB) = str_replace_all(names(adult_DB), "X", "MF")

juv_DB = read.csv(
    "data/diversity_data/Matrix_Juv_dominant.csv",
    sep = ";"
)
names(juv_DB) = str_replace_all(names(juv_DB), "X", "MF")

### Select final dataset
adult_selected = adult_DB %>% select(
    -c("MF1230","MF1257", "MF374", "F1")
)

write.table(
    adult_selected,
    "data/diversity_data/dominant_adult_selected.csv",
    sep = ";",
    row.names = F
)
