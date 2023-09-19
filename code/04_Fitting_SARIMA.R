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
    "data/Matrix_dominant.csv",
    sep = ";"
)
names(data_abundance) = str_replace_all(names(data_abundance), "X", "MF")

# Split train/test dataset
data_abundance_train = data_abundance[1:26,]
data_abundance_test = data_abundance[27:36,]

### Looping
forecast_SARIMA = data.frame("time_step" = data_abundance$time_step) %>% select(-time_step)

for (col_number in 1:(ncol(data_abundance_train)-1)) {
    # print(col_number)
    print(
        names(data_abundance_train)[col_number]
    )

   MF_data = data_abundance_train[,col_number]
   
   ## transform to time series objects

   MF_TS = ts(
    MF_data,
    start = min(data_abundance_train$time_step),
    end = max(data_abundance_train$time_step),
    frequency = 1
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
}

names(forecast_SARIMA) = names(data_abundance_train)[1:(ncol(data_abundance_train)-1)]
# forecast_SARIMA[forecast_SARIMA < 0] = 0



write.table(
    forecast_SARIMA,
    "data/SARIMA/output_SARIMA.csv",
    sep = ";",
    row.names = F
)
