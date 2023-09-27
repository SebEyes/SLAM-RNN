## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
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

### Visualise dataset
graph_TimeSeries = function(dataset){

    data_plot = dataset %>% select(-sampling_period) %>% melt(id.vars = "step")

    graph = ggplot(
        data = data_plot,
        aes(
            x = step,
            y = value,
            group = variable
        )
    ) + geom_point() + geom_line() + facet_wrap(.~variable, scales = "free")

    graph

}

ggsave(
    "docs/graphs_diversity_data/SLAM_V69/Time_series_adults.jpg",
    graph_TimeSeries(adult_DB),
    width = 20, 
    height = 20
)

ggsave(
    "docs/graphs_diversity_data/SLAM_V69/Time_series_total.jpg",
    graph_TimeSeries(total_DB),
    width = 20,
    height = 20
)

ggsave(
    "docs/graphs_diversity_data/SLAM_V69/Time_series_juveniles.jpg",
    graph_TimeSeries(juv_DB),
    width = 20,
    height = 20
)


### Select final dataset
# Remove MF with chaotic time series (rare species ?)
adult_selected = adult_DB %>% select(
    -c(
        "MF1223", #Aleyrodidae sp. complex
        "MF1257", #Anaspis sp.
        "MF2", #Tenuiphantes miguelensis (Wunderlich, 1992)
        "F1", #Lasius grandis Forel, 1909
        "MF374", #Bertkauia lucifuga (Rambur, 1842)
        "MF697" #Microlinyphia johnsoni (Blackwall, 1859)
    )
)

write.table(
    adult_selected,
    "data/diversity_data/dominant_adult_selected.csv",
    sep = ";",
    row.names = F
)
