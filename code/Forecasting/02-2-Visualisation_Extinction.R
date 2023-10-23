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
data_path = "data/extinction_scenarios"
extinction_scenarios = list.files(data_path, pattern = "csv", recursive = F)
MF_list = str_remove_all(extinction_scenarios, ".csv")

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
extinction = data.frame(
    "Hill.0" = NA,
    "Hill.1" = NA,
    "Hill.2" = NA,
    "MF_extinct" = NA,
    "forecasted_step" = NA
) %>% na.omit()

extinction_trend_test = data.frame(
    "Hill.0_tau" = NA,
    "Hill.1_tau" = NA,
    "Hill.2_tau" = NA,
    "Hill.0_pvalue" = NA,
    "Hill.1_pvalue" = NA,
    "Hill.2_pvalue" = NA, 
    "MF_extinct" = NA
) %>% na.omit()

extinction_value_test = data.frame(
    "Hill.0_mean" = NA,
    "Hill.1_mean" = NA,
    "Hill.2_mean" = NA,
    "Hill.0_sd" = NA,
    "Hill.1_sd" = NA,
    "Hill.2_sd" = NA,
    "MF_extinct" = NA
) %>% na.omit()

#Start loop
for (scenario_nb in 1:length(extinction_scenarios)) {
    ## Import data
    data_scenario = read.csv(
        path(
            data_path, extinction_scenarios[scenario_nb]
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
        "MF_extinct" = MF_list[scenario_nb]
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
    "MF_extinct" = MF_list[scenario_nb]
) %>% na.omit()

    extinction_value_test = rbind(
        extinction_value_test,
        value_test
    )

    extinction_trend_test = rbind(
        extinction_trend_test,
        value_trend_test
    )

    MF_extinct = rep(
        MF_list[scenario_nb],
        40
    ) %>% as.data.frame

    data_extinction = data.frame(
        cbind(
            MF_extinct, H0,H1,H2
        )
    ) %>% rename("MF_extinct" = ".")
    data_extinction$forecasted_step = 40 + as.numeric(row.names(data_extinction))

    extinction = rbind(
        extinction, 
        data_extinction
    )

    diversity_metrics = select(
        data_extinction,
        -MF_extinct
    )

    file_name = path("data/extinction_scenarios/diversity_metrics", extinction_scenarios[scenario_nb])

    write.table(
        diversity_metrics,
        file_name,
        sep = ";",
        row.names = F
    )
}

extinction_trend_test = merge(
    extinction_trend_test,
    select(
        MF_info,
        MF,
        scientificName
    ),
    by.x = "MF_extinct",
    by.y = "MF"
)

extinction_value_test = merge(
    extinction_value_test,
    select(
        MF_info,
        MF,
        scientificName
    ),
    by.x = "MF_extinct",
    by.y = "MF"
)

write.table(
    extinction_value_test,
    path("data/extinction_scenarios/diversity_metrics/summary/00_Summary_metrics.csv"),
        sep = ";",
        row.names = F
    )

write.table(
    extinction_trend_test,
    path("data/extinction_scenarios/diversity_metrics/summary/01_Summary_trend.csv"),
        sep = ";",
        row.names = F
    )

#### KW Tests
extinction_KW_testValue = extinction %>% select(-forecasted_step)
extinction_KW_testValue = melt(extinction_KW_testValue, id.vars = c("MF_extinct"))
 
extinction_KW_H0 = kruskal.test(
    x = extinction_KW_testValue$value[extinction_KW_testValue$variable == "Hill.0"],
    g = extinction_KW_testValue$MF_extinct[extinction_KW_testValue$variable == "Hill.0"]
)
extinction_KW_H1 = kruskal.test(
    x = extinction_KW_testValue$value[extinction_KW_testValue$variable == "Hill.1"],
    g = extinction_KW_testValue$MF_extinct[extinction_KW_testValue$variable == "Hill.1"]
)
extinction_KW_H2 = kruskal.test(
    x = extinction_KW_testValue$value[extinction_KW_testValue$variable == "Hill.2"],
    g = extinction_KW_testValue$MF_extinct[extinction_KW_testValue$variable == "Hill.2"]
)

KW_test = data.frame(
    metric = c("H0", "H1", "H2"),
    KW_chi2 = c(extinction_KW_H0$statistic, extinction_KW_H1$statistic, extinction_KW_H2$statistic),
    df = c(extinction_KW_H0$parameter, extinction_KW_H1$parameter, extinction_KW_H2$parameter),
    "p-value" = c(extinction_KW_H0$p.value, extinction_KW_H1$p.value, extinction_KW_H2$p.value)
)

### Wilcox test
wilcox_Extinction_H0 = extinction_KW_testValue %>% filter(variable == "Hill.0") %>% wilcox_test(value~MF_extinct)
wilcox_Extinction_H1 = extinction_KW_testValue %>% filter(variable == "Hill.1") %>% wilcox_test(value~MF_extinct)
wilcox_Extinction_H2 = extinction_KW_testValue %>% filter(variable == "Hill.2") %>% wilcox_test(value~MF_extinct)


write.table(
    KW_test,
    "data/extinction_scenarios/diversity_metrics/summary/02_KW_metrics.csv",
    sep = ";",
    row.names = F
)

#### Plot
extinction = melt(extinction, id.vars = c("MF_extinct", "forecasted_step"))




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

extinction = merge(
    extinction,
    MF_name,
    by.x = "MF_extinct",
    by.y = "MF"
)

ggplot(
    extinction,
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
    ncol = 4) +
labs(
    x = "Season number",
    y = "Equivalent number of species",
    color = "Alpha diversity metric:"
)+ 
theme(
    strip.text.x = ggtext::element_markdown(angle = 0),
    strip.background.x = element_rect(color = "black")
)

ggsave("docs/graphs_extinction/extinction.jpg",
    width = 20,
    height = 40
)

