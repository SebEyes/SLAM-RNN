## Package
require(fs)
require(stringr)
require(dplyr)
require(tidyr)
require(ggplot2)
require(reshape2)
require(ggthemes)
require(gambin)
require(rstatix)
rm(list = ls())

## List files
data_path = "data/invasion_scenarios"
invasion_scenarios = list.files(data_path, pattern = "csv", recursive = F)
MF_list = str_remove_all(invasion_scenarios, ".csv")


null_situation = read.csv("data/forecast best modelV9/forecasted_data.csv")

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

# Initialise output
# Null situation
data_null = as.data.frame(t(null_situation))

gambin = data.frame(
    alpha = NA
) %>% na.omit()

for (time in 1:40){
    print(time)
    gambin = rbind(
        gambin,
        data.frame(
            alpha = summary(
                fit_abundances(
                    data_null[,time],
                    cores = 3
                )
            )$alpha
        )
    )
}

invasion = data.frame(
    "alpha" = NA,
    "MF_invaded" = NA,
    "forecasted_step" = NA
) %>% na.omit()

gambin$time_step = as.numeric(row.names(gambin))
gambin$MF_invaded = "No invasion"

invasion = rbind(invasion, gambin)


#Start loop
for (scenario_nb in 1:length(invasion_scenarios)) {
    ## Import data
    data_scenario = read.csv(
        path(
            data_path, invasion_scenarios[scenario_nb]
        )
    )

    ## Compute diversity metrics
    data = as.data.frame(t(data_scenario))

    gambin = data.frame(
        alpha = NA
    ) %>% na.omit()

    for (time in 1:(nrow(data_scenario)-1)){

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
    gambin$MF_invaded = invasion_scenarios[scenario_nb]

    invasion = rbind(invasion, gambin)
}
invasion$MF_invaded = str_remove_all(invasion$MF_invaded, ".csv")

#### Plot
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

invasion = merge(
    invasion,
    MF_name,
    by.x = "MF_invaded",
    by.y = "MF",
    all.x = T
)
invasion$scientificName[is.na(invasion$scientificName)] = "No invasion"

invasion$season = rep(
    c("Spring", "Summer", "Autumn", "Winter"),
    (length(unique(invasion$time_step))/4) * length(unique(invasion$MF_invaded))
) 
## Réordonnancement de invasion$season
invasion$season <- invasion$season %>%
  fct_relevel(
    "Spring", "Summer", "Autumn", "Winter"
  )

ggplot(
    invasion,
    aes(
        x = time_step,
        y = alpha
    )
) + 
geom_point(
    aes(color = season)
) + 
geom_line(aes(group = MF_invaded)) + 
theme_stata() +
facet_wrap(
    .~scientificName,
    ncol = 1) +
labs(
    x = "Season number",
    y = "GamBin Alpha value",
    color = "Season: "
)+ 
theme(
    strip.text.x = ggtext::element_markdown(angle = 0),
    strip.background.x = element_rect(color = "black")
)

ggsave("docs/graphs_invasion/invasion_GAMBIN_V2.jpg",
    width = 20,
    height = 20
)

### Stats
KW_test = kruskal_test(
    invasion,
    formula = alpha ~ MF_invaded
)