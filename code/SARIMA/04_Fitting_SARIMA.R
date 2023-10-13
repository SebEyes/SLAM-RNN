## Package
require(stringr)
require(tidyr)
require(dplyr)
require(ggplot2)
require(reshape2)
require(forecast)

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
data_abundance_train = data_abundance[1:30,]
data_abundance_test = data_abundance[31:40,]

### Loop
forecast_SARIMA = data.frame(
    "step" = data_abundance$step
    ) %>% 
    select(step)

system.time(for (col_number in 2:(ncol(data_abundance_train))) {
    # print(col_number)
    print(
        names(data_abundance_train)[col_number]
    )

   MF_data = data_abundance_train[,col_number]
   
   ## transform to time series objects

   MF_TS = ts(
    MF_data,
    frequency = 4
    )

    ## Find the best SARIMA model
    MF_data_fit = auto.arima(
        y = MF_TS,
        stationary = F,
        seasonal = TRUE,
        stepwise = FALSE,
        parallel = TRUE
    )
    # Gather fitted data
    MF_fitted =  MF_data_fit$fitted

    # Gather forecasting for test data
    MF_forecast = forecast(MF_data_fit, h = 10)
    
    # # Gather the model's parameters
    # model = summary(MF_data_fit)
    # model$arma

    # SARIMA full
    SARIMA_data = append(MF_fitted, MF_forecast$mean)
    forecast_SARIMA = cbind(forecast_SARIMA, SARIMA_data)
})

names(forecast_SARIMA) = names(data_abundance_train)
forecast_SARIMA[forecast_SARIMA < 0] = 0



write.table(
    forecast_SARIMA,
    "data/SARIMA/output_SARIMA.csv",
    sep = ";",
    row.names = F
)