require(ggplot2)
require(fs)
require(tidyr)
require(dplyr)
require(stringr)
require(reshape2)

data_path = path(
    "data",
    "extinction_scenarios",
    "gradual_extinction"
)

data_MF7 = list.files(
    data_path,
    pattern = "csv"
)
data_MF7 = data_MF7[str_detect(data_MF7, "MF7_")]

data_plot = data.frame(
    variable = NA,
    value = NA,
    time_step = NA,
    scenario = NA
) %>% na.omit()


for(index_scenario in 1:length(data_MF7)){
        data_file = read.csv(
        path(
            data_path,
            data_MF7[index_scenario]
        )
    )

    data_file$time_step = row.names(data_file)
    data_file$scenario = data_MF7[index_scenario]

    data_melt = melt(
        data_file,
        id.vars = c("time_step", "scenario")
    )

    data_plot = rbind(
        data_plot,
        data_melt
    )
}

## Réordonnancement de data_plot$scenario
data_plot$scenario <- data_plot$scenario %>%
  fct_relevel(
    "MF7_10_%.csv", "MF7_20_%.csv", "MF7_30_%.csv", "MF7_40_%.csv",
    "MF7_50_%.csv", "MF7_60_%.csv", "MF7_70_%.csv", "MF7_80_%.csv",
    "MF7_90_%.csv", "MF7_100_%.csv"
  )


ggplot(
    data = data_plot,
    aes(
        x = time_step,
        y = value,
        group = variable,
        color = scenario
    )
) + geom_point() + geom_line() + facet_wrap(.~variable, scales = "free")

ggsave("MF7_extinction.jpg", height = 20, width =  20)
