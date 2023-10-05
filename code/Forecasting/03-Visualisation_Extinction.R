## Package
require(fs)
require(stringr)
require(dplyr)
require(tidyr)
require(ggplot2)
require(BAT)
require(reshape2)

## List files
data_path = "data/extinction_scenarios"
extinction_scenarios = list.files(data_path, pattern = "csv", recursive = F)
MF_list = str_remove_all(extinction_scenarios, ".csv")

# Initialise output
extinction = data.frame(
    "Hill.0" = NA,
    "Hill.1" = NA,
    "Hill.2" = NA,
    "MF_extinct" = NA,
    "forecasted_step" = NA
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

extinction = melt(extinction, id.vars = c("MF_extinct", "forecasted_step"))

ggplot(
    extinction,
    aes(
        x = forecasted_step,
        y = value,
        color = variable
    )
) + geom_point() + geom_line(aes(group = variable)) + facet_wrap(.~MF_extinct)

ggsave("docs/graphs_extinction/extinction.jpg",
    width = 20,
    height = 20
)
