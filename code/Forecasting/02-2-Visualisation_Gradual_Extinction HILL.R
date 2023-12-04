## Package
require(fs)
require(stringr)
require(dplyr)
require(tidyr)
require(ggplot2)
require(BAT)
require(reshape2)
require(forcats)
require(ggthemes)
require(rstatix)

## List files
data_path = "data/extinction_scenarios/gradual_extinction"
extinction_scenarios = list.files(data_path, pattern = "csv", recursive = F)
MF_list = str_remove_all(extinction_scenarios, "_.._%.csv")
scenario_list = paste("_",seq(from = 10, to = 100, by = 10),"_", sep = "")

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

    data_hill = data.frame(
        time_step = NA,
        scenario = NA,
        Hill.0 = NA,
        Hill.1 = NA,
        Hill.2 = NA
    ) %>% na.omit()

    for (scenario in 1:length(list_data_scenario)) {

    data = read.csv(
        path(
            data_path, list_data_scenario[scenario]
        ),
        sep = ","
        )

        Hill = data.frame(
            hill(data, q = 0),
            hill(data, q = 1),
            hill(data, q = 2)
        )


        Hill$time_step = as.numeric(row.names(Hill))
        Hill$scenario = list_data_scenario[scenario]

        data_hill = rbind(data_hill, Hill)
    }

    data_melt = melt(
        data_hill,
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
    "10", "20", "30", "40", "50", "60", "70", "80", "90", "100"
  )

for(hill_number in unique(data_plot_scenario$variable)){
    print(hill_number)
    hill_number = as.character(hill_number)

    plot = ggplot(
        data = data_plot_scenario %>% filter(variable == hill_number),
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
    y = "Equivalent number of species",
    color = "Percentage of abundance removed:"
)+ 
theme(
    strip.text.x = ggtext::element_markdown(angle = 0),
    strip.background.x = element_rect(color = "black")
)

    plot_name = path(
        paste(
            hill_number,
            "_plot.jpg",
            sep = ""
        )
    )

    ggsave(
        plot = plot,
        filename = plot_name,
        height = 20,
        width = 20
    )
}
