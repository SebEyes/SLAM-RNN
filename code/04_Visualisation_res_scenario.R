## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
require(ggrepel)

#####
## Mean accuracy model V6 with 50_000 epochs training (output S0)
#####

## Database
acc_model = read.csv(
    "data/results_scenario/S0[best_model_selection]/modelV6 selection.csv"
)
# remove run 0
acc_model = acc_model %>% filter(run > 0)

acc_model$mean_accuracy = acc_model$mean_accuracy * 100

## Boxplot mean accuracy
BoxPlot_accurracy = ggplot(
    data = acc_model,
    aes(
        x = "Accuracy model V6",
        y = mean_accuracy
    )
) + 
geom_boxplot() +
scale_y_continuous(limits = c(0,100)) + 
geom_text_repel(
    data = subset(acc_model, acc_model$mean_accuracy == max(acc_model$mean_accuracy)),
    aes(
        label = paste(
            "Best model (",
            round(max(acc_model$mean_accuracy),1),
            "%)",
            sep = ""
            )
    ),
    size = 5,
    box.padding = unit(-7, "lines")
)+ 
labs(
    x = "",
    y = "Mean accuracy (%)"
) 

BoxPlot_accurracy

ggsave(
    "docs/Accuracy_Model_V6.jpg",
    width = 4,
    height = 5,
    units = "in"
)

## Dispersion statistics
summary(acc_model$mean_accuracy)
