## Package
require(fs)
require(stringr)
require(dplyr)
require(tidyr)
require(ggplot2)
require(BAT)
require(reshape2)
require(ggthemes)
require(Kendall)
require(rstatix)

## List files
data_path = "data/invasion_scenarios"
invasion_scenarios = list.files(data_path, pattern = "csv", recursive = F)
MF_list = str_remove_all(invasion_scenarios, ".csv")

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
invasion = data.frame(
    "Hill.0" = NA,
    "Hill.1" = NA,
    "Hill.2" = NA,
    "MF_invaded" = NA,
    "forecasted_step" = NA
) %>% na.omit()

invasion_trend_test = data.frame(
    "Hill.0_tau" = NA,
    "Hill.1_tau" = NA,
    "Hill.2_tau" = NA,
    "Hill.0_pvalue" = NA,
    "Hill.1_pvalue" = NA,
    "Hill.2_pvalue" = NA,
    "MF_invaded" = NA
) %>% na.omit()

invasion_value_test = data.frame(
    "Hill.0_mean" = NA,
    "Hill.1_mean" = NA,
    "Hill.2_mean" = NA,
    "Hill.0_sd" = NA,
    "Hill.1_sd" = NA,
    "Hill.2_sd" = NA,
    "MF_invaded" = NA
) %>% na.omit()

#Start loop
for (scenario_nb in 1:length(invasion_scenarios)) {
    ## Import data
    data_scenario = read.csv(
        path(
            data_path, invasion_scenarios[scenario_nb]
        )
    )

    ## Compute diversity metrics
    H0 = hill(data_scenario) %>% as.data.frame()
    H1 = hill(data_scenario, q = 1) %>% as.data.frame()
    H2 = hill(data_scenario, q = 2) %>% as.data.frame()

    value_test = data.frame(
        "Hill.0_mean" = mean(H0$'Hill 0'),
        "Hill.1_mean" = mean(H1$'Hill 1'),
        "Hill.2_mean" = mean(H2$'Hill 2'),
        "Hill.0_sd" = sd(H0$'Hill 0'),
        "Hill.1_sd" = sd(H1$'Hill 1'),
        "Hill.2_sd" = sd(H2$'Hill 2'),
        "MF_invaded" = MF_list[scenario_nb]
    )

    H0_TS = ts(H0,frequency = 4)
    H1_TS = ts(H1,frequency = 4)
    H2_TS = ts(H2,frequency = 4)

    value_trend_test = data.frame(
    "Hill.0_tau" = as.numeric(SeasonalMannKendall(H0_TS)$tau),
    "Hill.1_tau" = as.numeric(SeasonalMannKendall(H1_TS)$tau),
    "Hill.2_tau" = as.numeric(SeasonalMannKendall(H2_TS)$tau),
    "Hill.0_pvalue" = as.numeric(SeasonalMannKendall(H0_TS)$sl),
    "Hill.1_pvalue" = as.numeric(SeasonalMannKendall(H1_TS)$sl),
    "Hill.2_pvalue" = as.numeric(SeasonalMannKendall(H2_TS)$sl),
    "MF_invaded" = MF_list[scenario_nb]
) %>% na.omit()

    invasion_value_test = rbind(
        invasion_value_test,
        value_test
    )

    invasion_trend_test = rbind(
        invasion_trend_test,
        value_trend_test
    )

    MF_invaded = rep(
        MF_list[scenario_nb],
        40
    ) %>% as.data.frame

    data_invasion = data.frame(
        cbind(
            MF_invaded, H0,H1,H2
        )
    ) %>% rename("MF_invaded" = ".")
    data_invasion$forecasted_step = 40 + as.numeric(row.names(data_invasion))

    invasion = rbind(
        invasion,
        data_invasion
    )

    diversity_metrics = select(
        data_invasion,
        -MF_invaded
    )

    file_name = path("data/invasion_scenarios/diversity_metrics", extinction_scenarios[scenario_nb])

    write.table(
        diversity_metrics,
        file_name,
        sep = ";",
        row.names = F
    )
}

invasion_trend_test = merge(
    invasion_trend_test,
    select(
        MF_info,
        MF,
        scientificName
    ),
    by.x = "MF_invaded",
    by.y = "MF"
)

invasion_value_test = merge(
    invasion_value_test,
    select(
        MF_info,
        MF,
        scientificName
    ),
    by.x = "MF_invaded",
    by.y = "MF"
)

write.table(
    invasion_value_test,
    path("data/invasion_scenarios/diversity_metrics/summary/00_Summary_metrics.csv"),
        sep = ";",
        row.names = F
    )

write.table(
    invasion_trend_test,
    path("data/invasion_scenarios/diversity_metrics/summary/01_Summary_trend.csv"),
        sep = ";",
        row.names = F
    )

#### KW Tests
invasion_KW_testValue = invasion %>% select(-forecasted_step)
invasion_KW_testValue = melt(invasion_KW_testValue, id.vars = c("MF_invaded"))

invasion_KW_H0 = kruskal.test(
    x = invasion_KW_testValue$value[invasion_KW_testValue$variable == "Hill.0"],
    g = invasion_KW_testValue$MF_invaded[invasion_KW_testValue$variable == "Hill.0"]
)
invasion_KW_H1 = kruskal.test(
    x = invasion_KW_testValue$value[invasion_KW_testValue$variable == "Hill.1"],
    g = invasion_KW_testValue$MF_invaded[invasion_KW_testValue$variable == "Hill.1"]
)
invasion_KW_H2 = kruskal.test(
    x = invasion_KW_testValue$value[invasion_KW_testValue$variable == "Hill.2"],
    g = invasion_KW_testValue$MF_invaded[invasion_KW_testValue$variable == "Hill.2"]
)

KW_test = data.frame(
    metric = c("H0", "H1", "H2"),
    KW_chi2 = c(invasion_KW_H0$statistic, invasion_KW_H1$statistic, invasion_KW_H2$statistic),
    df = c(invasion_KW_H0$parameter, invasion_KW_H1$parameter, invasion_KW_H2$parameter),
    "p-value" = c(invasion_KW_H0$p.value, invasion_KW_H1$p.value, invasion_KW_H2$p.value)
)

write.table(
    KW_test,
    "data/invasion_scenarios/diversity_metrics/summary/02_KW_metrics.csv",
    sep = ";",
    row.names = F
)

#### Plot
invasion = melt(invasion, id.vars = c("MF_invaded", "forecasted_step"))


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
    by.y = "MF"
)

ggplot(
    invasion,
    aes(
        x = forecasted_step,
        y = value,
        color = variable
    )
) + 
geom_point() + 
geom_line(aes(group = variable)) + 
theme_stata() +
facet_wrap(
    .~scientificName,
    ncol = 1) +
labs(
    x = "Season number",
    y = "Equivalent number of species",
    color = "Alpha diversity metric:"
)+ 
theme(
    strip.text.x = ggtext::element_markdown(angle = 0),
    strip.background.x = element_rect(color = "black")
)

ggsave("docs/graphs_invasion/invasion.jpg",
    width = 20,
    height = 20
)

