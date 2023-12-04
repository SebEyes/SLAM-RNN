## Package
require(fs)
require(stringr)
require(dplyr)
require(tidyr)
require(ggplot2)
require(reshape2)
require(forcats)
require(ggthemes)
require(rstatix)
require(gambin)

## List files
data_path = "data/extinction_scenarios/gradual_extinction"
extinction_scenarios = list.files(data_path, pattern = "csv", recursive = F)
MF_list = str_remove_all(extinction_scenarios, "_.._%.csv")
scenario_list = paste("_",seq(from = 0, to = 100, by = 10),"_", sep = "")

# MF list
MF_info = read.csv(
    "data/diversity_data/SuppS2_MF_Info.csv",
    sep = ";"
)
MF_info$MF = paste("MF", MF_info$MF, sep = "")
MF_name = select(
    MF_info,
    MF,
    genus,
    specificEpithet,
    infraspecificEpithet,
    scientificNameAuthorship,
    scientificName
)

data_plot_scenario = data.frame(
    time_step = NA,
    scenario = NA,
    variable = NA,
    value = NA
) %>% na.omit()

for (scenario_global in 1:length(scenario_list)) {

    scenario_selected = scenario_list[scenario_global]

    list_data_scenario = extinction_scenarios[str_detect(extinction_scenarios, scenario_selected)]

    data_gambin = data.frame(
        time_step = NA,
        scenario = NA,
        alpha = NA
    ) %>% na.omit()

    for (scenario in 1:length(list_data_scenario)) {

        data = read.csv(
            path(
                data_path, list_data_scenario[scenario]
            ),
            sep = ","
            )
    
        data = as.data.frame(t(data))

        gambin = data.frame(
            alpha = NA
        ) %>% na.omit()

        for (time in 1:40){

            gambin = rbind(
                gambin,
                data.frame(
                    alpha = summary(
                        fit_abundances(
                            data[,time],
                            cores = 3
                        )
                    )$alpha
                )
            )
        }

        gambin$time_step = as.numeric(row.names(gambin))
        gambin$scenario = list_data_scenario[scenario]

        data_gambin = rbind(data_gambin, gambin)
    }

    data_season = data_gambin

    data_melt = melt(
        data_gambin,
        id.vars = c("time_step", "scenario")
    )

    data_plot_scenario = rbind(
        data_plot_scenario,
        data_melt
    )
}


data_plot_scenario = separate(
    data_plot_scenario,
    col = scenario,
    into = c("MF_impacted","scenario"),
    sep = "_",
    remove = F,
    extra = "drop"
)

data_stat = data_plot_scenario

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

data_plot_scenario = merge(
    data_plot_scenario,
    MF_name,
    by.x = "MF_impacted",
    by.y = "MF"
)

## Réordonnancement de data_plot_scenario$scenario
data_plot_scenario$scenario <- data_plot_scenario$scenario %>%
  fct_relevel(
    "0","10", "20", "30", "40", "50", "60", "70", "80", "90", "100"
  )

plot = ggplot(
    data = data_plot_scenario,
    aes(
        x = time_step,
        y = value,
        group = scenario,
        color = scenario
    )
) + 
geom_point() + 
geom_line()+ 
theme_stata() +
facet_wrap(
.~scientificName,
ncol = 4) +
labs(
x = "Season number",
y = "Gambin Alpha",
color = "Percentage of abundance removed:"
)+ 
theme(
strip.text.x = ggtext::element_markdown(angle = 0),
strip.background.x = element_rect(color = "black")
)

plot_name = path(
    paste(
        "Gambin_alpha",
        "_plot_V2.jpg",
        sep = ""
    )
)

# ggsave(
#     plot = plot,
#     filename = plot_name,
#     height = 20,
#     width = 20
# )


## Stats
data_stat$scenario = as.factor(data_stat$scenario)

kruskal_scenario_MF = data.frame(
    ".y." = NA,
    n = NA,
    statistic = NA,
    df = NA,
    p = NA,
    method = NA
) %>% na.omit()

for(scenario in unique(data_stat$scenario)){
    print(scenario)
    
    data_selected = data_stat[data_stat$scenario == scenario,]
    
    kruskal_scenario = kruskal_test(
        data = data_selected,
        formula = value ~ MF_impacted
    )

    kruskal_scenario_MF = rbind(
        kruskal_scenario_MF,
        kruskal_scenario
    )
}

kruskal_scenario_MF$.y. = c(0:10)*10
kruskal_scenario_MF = kruskal_scenario_MF %>% rename(
    "scenario" = ".y."
)

# write.table(
#     kruskal_scenario_MF,
#     "data/extinction_scenarios/gradual_extinction/diversity_metrics/kruskal_scenario.csv",
#     sep = ";",
#     row.names = F
# )

data_stat$season = rep(
    c("Spring","Summer", "Autumn", "Winter"),
    (length(unique(data_stat$time_step))/4) * length(unique(data_stat$MF_impacted)) * length(unique(data_stat$scenario))
)

## Réordonnancement de data_stat$scenario
data_stat$scenario <- data_stat$scenario %>%
  fct_relevel(
    "0", "10", "20", "30", "40", "50", "60", "70", "80", "90",
    "100"
  )
## Réordonnancement de data_stat$season
data_stat$season <- data_stat$season %>%
  fct_relevel(
    "Spring","Summer", "Autumn", "Winter"
  )

ggplot(
    data_stat,
    aes(
        x = scenario,
        y = value,
        fill = season
    )
) + geom_boxplot() + labs(
    x = "Percentage of abundance removed",
    y = "GamBin alpha"
) + theme_stata() + facet_wrap(.~season) +theme(legend.position = "none")

ggsave(
    "docs/graphs_extinction/Gambin_season.jpg",
    width = 10,
    height = 10
)
