## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)

#####
## Mean accuracy model V6 with 50_000 epochs training (output S0)
#####

## Database
acc_model = read.csv(
    "data/results_scenario/S0[best_model_selection]/modelV6 selection.csv"
)
# remove run 0
acc_model = acc_model %>% filter(run > 0)

## Boxplot mean accuracy
ggplot(
    data = acc_model,
    aes(
        y = mean_accuracy
    )
) + 
geom_boxplot() +
scale_y_continuous(limits = c(0,1)) + 
labs(
    x = "",
    y = "Mean accuracy"
)

## Dispersion statistics
summary(acc_model$mean_accuracy)