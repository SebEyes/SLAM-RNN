## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
require(reshape2)
require(mgcv)

## Loading data
# Real data
data_abundance = read.csv(
    "data/diversity_data/SLAM_V69/selected/dominant_adult_selected.csv",
    sep = ";"
)
# Keep tracking time information
time_info = select(data_abundance, step, sampling_period)
data_abundance = data_abundance %>% select(-sampling_period)

# Split train/test dataset
data_abundance_train = data_abundance[1:30,] #75% of data to fit
data_abundance_test = data_abundance[31:40,] #25% of the data to test accuracy

### Loop
forecast_LOESS = data.frame(
    "step" = data_abundance$step
    ) %>% 
    select(step)

system.time(for (col_number in 2:(ncol(data_abundance_train))) {
    # print(col_number)
    print(
        names(data_abundance_train)[col_number]
    )

   MF_data = data_abundance_train[,col_number]

    MF_data = data.frame(
        abundance = MF_data,
        step = data_abundance_train$step
    )
    ## Fit LOESS
    MF_data_fit = loess(abundance ~ step, data = MF_data, model = T, control = loess.control(surface = "direct"))

    
    # Gather fitted data
    MF_fitted =  MF_data_fit$fitted

    # Gather forecasting for test data

    test_step = data.frame(
        step = data_abundance_test$step
    )
    MF_forecast = predict(MF_data_fit, test_step)
    
    # # Gather the model's parameters
    # model = summary(MF_data_fit)
    # model$arma

    # SARIMA full
    LOESS_data = append(MF_fitted, MF_forecast)
    forecast_LOESS = cbind(forecast_LOESS, LOESS_data)
})

names(forecast_LOESS) = names(data_abundance_train)
forecast_LOESS[forecast_LOESS < 0] = 0



write.table(
    forecast_LOESS,
    "data/LOESS/output_LOESS.csv",
    sep = ";",
    row.names = F
)