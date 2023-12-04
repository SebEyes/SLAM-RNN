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


### Composition samples
diversity_data = read.csv(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    sep = ";"
)

diversity_data = separate(
    diversity_data,
    col = "sampling_period",
    into = c("season","year"),
    sep = "_",
    extra = "drop"
)
diversity_data = select(diversity_data, -step)

diversity_data = melt(diversity_data, id.vars = c("season", "year"))

rank_ab = diversity_data %>% group_by(season,variable) %>% summarise(ab = sum(value)) %>% arrange(ab)
rank_ab = rank_ab %>% arrange(season,-ab)

rank_ab$rank = rep(1:39, 4)
rank_ab  = rank_ab %>% select(-ab)

diversity_data = merge(
    diversity_data,
    rank_ab,
    by = c("season", "variable")
)

total_ab = diversity_data %>% group_by(variable, rank, year) %>% summarise(
    value = sum(value),
    season = "Full year"
    )
diversity_data = rbind(
    diversity_data,
    total_ab
)

diversity_data$season = as.factor(diversity_data$season)
diversity_data$year = as.numeric(diversity_data$year)
diversity_data$variable = as.factor(diversity_data$variable)

## Réordonnancement de diversity_data$season
diversity_data$season <- diversity_data$season %>%
  fct_relevel(
    "Full year", "winter", "spring", "summer", "autumn"
  )
## Recodage de diversity_data$season
diversity_data$season <- diversity_data$season %>%
  fct_recode(
    "Winter" = "winter",
    "Spring" = "spring",
    "Summer" = "summer",
    "Autumn" = "autumn"
  )

ggplot(
    data = arrange(diversity_data,rank),
    aes(
        x = reorder(variable,rank),
        y = log(value),
        fill = season
    )
) + 
    geom_boxplot() + 
    facet_wrap(
        nrow = 5,
        .~season, 
        scales = "free"
    ) + 
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 90)
    ) + labs(
        x = "Morphospecies code",
        y = "Log(abundance)"
    )

ggsave("abundance.jpg")
