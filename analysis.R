# ARIMA Time-Series Forecasting Replication
# Zahra Sadeghinejad
# Financial Time Series Project, 2023

# Replication of:
# Kumar, Manoj & Anand, Madhu
# "An Application of Time Series ARIMA Forecasting Model
# for Predicting Sugarcane Production in India"

# -------------------------------------------------------------------------
# 1. Setup and Data
# -------------------------------------------------------------------------

# Required packages
library(tseries)
library(forecast)

# Shared plotting functions for interactive and saved figures
source("plots.R")

# Load data
# Annual sugarcane production in India, crop years 1950-51 to 2011-12
# The observations are represented as 1951-2012 in the R time-series object.
mydata <- read.csv(
  "data/production.csv",
  sep = ",",
  header = TRUE,
  na.strings = "",
  stringsAsFactors = FALSE
)

print(head(mydata))

mydata$Production <- ts(
  mydata$Production,
  start = 1951,
  end = 2012
)

# -------------------------------------------------------------------------
# 2. Data Visualization and Differencing
# -------------------------------------------------------------------------

# Plot the original time series
plot_original_series(mydata$Production)

# First difference
mydata$diff1 <- c(NA, diff(mydata$Production))

mydata$diff1 <- ts(
  mydata$diff1,
  start = 1951,
  end = 2012
)

# Plot the first-differenced series
plot_first_difference(mydata$diff1)

# -------------------------------------------------------------------------
# 3. Stationarity Testing
# -------------------------------------------------------------------------

# Public replication uses an independently implemented
# ADF-OLS test with BIC lag selection.
source("adf_helpers.R")

# ADF unit-root test on the level series
test1 <- adf_bic_test(
  mydata$Production,
  trend = "ct"
)

print(test1)

# ADF unit-root test on the first-differenced series
test2 <- adf_bic_test(
  mydata$diff1[2:62],
  trend = "c"
)

print(test2)

# Additional ADF stationarity check using the tseries package
adf_tseries <- adf.test(mydata$diff1[2:62])
print(adf_tseries)

# -------------------------------------------------------------------------
# 4. Model Identification
# -------------------------------------------------------------------------

# ACF and PACF of the first-differenced series
acf_result <- Acf(
  mydata$diff1,
  lag.max = 20,
  main = "ACF of First-Differenced Sugarcane Production",
  ylim = c(-1, 1)
)

pacf_result <- Pacf(
  mydata$diff1,
  lag.max = 20,
  main = "PACF of First-Differenced Sugarcane Production",
  ylim = c(-1, 1)
)

print(acf_result)
print(pacf_result)

# -------------------------------------------------------------------------
# 5. Model Estimation and Selection
# -------------------------------------------------------------------------

# Fit candidate ARIMA models
model1 <- Arima(
  mydata$Production,
  order = c(2, 1, 0),
  method = "ML"
)

model2 <- Arima(
  mydata$Production,
  order = c(2, 1, 1),
  method = "ML"
)

model3 <- Arima(
  mydata$Production,
  order = c(2, 1, 2),
  method = "ML"
)

print(model1)
print(model2)
print(model3)

# Compare candidate ARIMA models using information criteria
model_comparison <- data.frame(
  Model = c(
    "ARIMA(2,1,0)",
    "ARIMA(2,1,1)",
    "ARIMA(2,1,2)"
  ),
  AIC = c(
    AIC(model1),
    AIC(model2),
    AIC(model3)
  ),
  AICc = c(
    model1$aicc,
    model2$aicc,
    model3$aicc
  ),
  BIC = c(
    BIC(model1),
    BIC(model2),
    BIC(model3)
  )
)

print(model_comparison)

# ARIMA(2,1,0) has the lowest AIC, AICc, and BIC
# and is therefore selected as the preferred model.

# -------------------------------------------------------------------------
# 6. Forecasting and Model Fit
# -------------------------------------------------------------------------

# 5-step-ahead forecast using the selected ARIMA(2,1,0) model
forecast_210 <- forecast(
  model1,
  h = 5,
  level = c(80, 95, 99.5)
)

print(forecast_210)

# Plot the five-year forecast
# Plot settings follow the original paper where possible.
# The y-axis limit of 400 is retained for replication consistency.
plot_forecast_210(forecast_210)

# Plot observed and fitted values for the selected model
plot_observed_vs_fitted(
  mydata$Production,
  forecast_210$fitted
)

# -------------------------------------------------------------------------
# 7. Residual Diagnostics
# -------------------------------------------------------------------------

# Residuals from the selected ARIMA(2,1,0) model
residuals_model1 <- ts(
  model1$residuals,
  start = 1951,
  end = 2012
)

plot(
  residuals_model1,
  col = "black",
  ylab = "Residual",
  xlab = "Year",
  type = "h",
  main = "Residuals from ARIMA(2,1,0)"
)

abline(h = 0)

# Standardize residuals using the estimated innovation standard deviation
standardized_residuals <- residuals_model1 / sqrt(model1$sigma2)

plot_standardized_residuals(standardized_residuals)

# Residuals displayed as a line plot
plot(
  residuals_model1,
  col = "black",
  ylab = "Residual",
  xlab = "Year",
  main = "Residuals from ARIMA(2,1,0)"
)

abline(h = 0)

# Standardized residuals displayed as a line plot
plot(
  standardized_residuals,
  col = "black",
  ylab = "Standardized Residual",
  xlab = "Year",
  main = "Standardized Residuals from ARIMA(2,1,0)"
)

abline(h = 0)

# Histogram of forecast errors with fitted normal-density curve
hist(
  residuals_model1,
  main = "Histogram of Forecast Errors",
  xlim = c(-100, 100),
  ylim = c(0, 0.04),
  col = "red",
  freq = FALSE,
  breaks = 20,
  xlab = "Forecast Error",
  ylab = "Density"
)

xfit <- seq(
  -100,
  max(residuals_model1),
  length.out = 100
)

yfit <- dnorm(
  xfit,
  mean = mean(residuals_model1),
  sd = sd(residuals_model1)
)

lines(
  xfit,
  yfit,
  col = "blue",
  lwd = 2
)

# Histogram of residuals with fitted normal-density curve
hist(
  residuals_model1,
  main = "Histogram of Residuals",
  xlim = c(-40, 60),
  ylim = c(0, 0.04),
  col = "white",
  freq = FALSE,
  breaks = 4,
  xlab = "Residual",
  ylab = "Density"
)

xfit_resid <- seq(
  -40,
  max(residuals_model1),
  length.out = 40
)

yfit_resid <- dnorm(
  xfit_resid,
  mean = mean(residuals_model1),
  sd = sd(residuals_model1)
)

lines(
  xfit_resid,
  yfit_resid,
  col = "red",
  lwd = 2
)

# Q-Q plot of residuals
plot_residual_qq(residuals_model1)

# ACF of residuals
plot_residual_acf(residuals_model1)

# PACF of residuals
pacf(
  residuals_model1,
  lag.max = 20,
  main = "PACF of ARIMA(2,1,0) Residuals"
)

# -------------------------------------------------------------------------
# 8. Residual Autocorrelation Tests
# -------------------------------------------------------------------------

# Tests for residual autocorrelation
# lag = 25 and fitdf = 5 are retained from the original replication
# to reproduce the reported diagnostic results.
ljung_box <- Box.test(
  residuals_model1,
  lag = 25,
  type = "Ljung-Box",
  fitdf = 5
)

box_pierce <- Box.test(
  residuals_model1,
  lag = 25,
  type = "Box-Pierce",
  fitdf = 5
)

print(ljung_box)
print(box_pierce) 

