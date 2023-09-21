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

### Graphs
total_dataplot = melt(
    total_DB,
    id.vars = c("step", "sampling_period")
)
ggplot(
    data = total_dataplot,
    aes(
        x = step, 
        y = value
    )
) + 
geom_point() + 
geom_line(aes(group = variable)) +
facet_wrap(
    .~variable,
    scales= "free_y"
)
# ggsave(
#     "docs/graphs_diversity_data/Time_series_total.jpg",
#     width = 20,
#     height = 20
# )

adult_dataplot = melt(
    adult_DB,
    id.vars = c("step", "sampling_period")
)
ggplot(
    data = adult_dataplot,
    aes(
        x = step, 
        y = value
    )
) + 
geom_point() + 
geom_line(aes(group = variable)) +
facet_wrap(
    .~variable,
    scales= "free_y"
)
# ggsave(
#     "docs/graphs_diversity_data/Time_series_adults.jpg",
#     width = 20,
#     height = 20
# )

juv_dataplot = melt(
    juv_DB,
    id.vars = c("step", "sampling_period")
)
ggplot(
    data = juv_dataplot,
    aes(
        x = step, 
        y = value
    )
) + 
geom_point() + 
geom_line(aes(group = variable)) +
facet_wrap(
    .~variable,
    scales= "free_y"
)
# ggsave(
#     "docs/graphs_diversity_data/Time_series_juvenile.jpg",
#     width = 20,
#     height = 20
# )