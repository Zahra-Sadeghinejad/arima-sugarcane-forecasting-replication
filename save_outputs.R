# save_outputs.R
# Reproduce the committed result tables and selected figures.
#
# Run from the repository root:
#   source("save_outputs.R")
#
# This script sources analysis.R, then regenerates:
#   - 4 CSV files in results/
#   - 7 PNG files in figures/

# -------------------------------------------------------------------------
# 1. Run the analysis without creating an extra Rplots.pdf
# -------------------------------------------------------------------------

temporary_plot_file <- tempfile(fileext = ".pdf")
grDevices::pdf(temporary_plot_file)

analysis_error <- NULL

tryCatch(
  source("analysis.R"),
  error = function(e) {
    analysis_error <<- e
  },
  finally = {
    if (grDevices::dev.cur() != 1) {
      grDevices::dev.off()
    }
    unlink(temporary_plot_file)
  }
)

if (!is.null(analysis_error)) {
  stop(analysis_error)
}

# -------------------------------------------------------------------------
# 2. Create output folders
# -------------------------------------------------------------------------

dir.create("results", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# -------------------------------------------------------------------------
# 3. Save result tables
# -------------------------------------------------------------------------

# Model comparison
write.csv(
  model_comparison,
  "results/model_comparison.csv",
  row.names = FALSE
)

# Forecasts
forecast_table <- data.frame(
  Year = as.integer(time(forecast_210$mean)),
  Point_Forecast = as.numeric(forecast_210$mean),
  Lo_80 = as.numeric(forecast_210$lower[, "80%"]),
  Hi_80 = as.numeric(forecast_210$upper[, "80%"]),
  Lo_95 = as.numeric(forecast_210$lower[, "95%"]),
  Hi_95 = as.numeric(forecast_210$upper[, "95%"]),
  Lo_99_5 = as.numeric(forecast_210$lower[, "99.5%"]),
  Hi_99_5 = as.numeric(forecast_210$upper[, "99.5%"])
)

write.csv(
  forecast_table,
  "results/forecasts_2013_2017.csv",
  row.names = FALSE
)

# Residual autocorrelation tests
residual_tests <- data.frame(
  Test = c("Ljung-Box", "Box-Pierce"),
  Statistic = c(
    as.numeric(ljung_box$statistic),
    as.numeric(box_pierce$statistic)
  ),
  df = c(
    as.numeric(ljung_box$parameter),
    as.numeric(box_pierce$parameter)
  ),
  p_value = c(
    ljung_box$p.value,
    box_pierce$p.value
  )
)

write.csv(
  residual_tests,
  "results/residual_autocorrelation_tests.csv",
  row.names = FALSE
)

# Stationarity tests
if (!exists("adf_tseries")) {
  adf_tseries <- tseries::adf.test(mydata$diff1[2:62])
}

stationarity_results <- data.frame(
  Series = c(
    "Level",
    "First difference",
    "First difference"
  ),
  Test = c(
    "ADF-OLS + BIC",
    "ADF-OLS + BIC",
    "ADF - tseries"
  ),
  Statistic = round(c(
    test1$stat,
    test2$stat,
    as.numeric(adf_tseries$statistic)
  ), 6),
  Lag = c(
    test1$k,
    test2$k,
    as.numeric(adf_tseries$parameter)
  ),
  Critical_Value_5pct = c(
    unname(test1$cv["5%"]),
    unname(test2$cv["5%"]),
    NA
  ),
  Conclusion = c(
    "Fail to reject unit root",
    "Reject unit root",
    "Reject unit root (p < 0.01)"
  )
)

write.csv(
  stationarity_results,
  "results/stationarity_tests.csv",
  row.names = FALSE
)

# -------------------------------------------------------------------------
# 4. Save selected figures
# -------------------------------------------------------------------------

# Figure 1: Original series
png(
  "figures/01_original_series.png",
  width = 1600,
  height = 1000,
  res = 160
)

plot(
  mydata$Production,
  type = "l",
  col = "black",
  xlab = "Year",
  ylab = "Production (million tonnes)",
  main = "Sugarcane Production in India, 1951-2012",
  lwd = 2.5,
  ylim = c(0, 450),
  xaxt = "n"
)

axis(
  side = 1,
  at = seq(1951, 2011, by = 10),
  labels = seq(1951, 2011, by = 10)
)

points(
  mydata$Production,
  pch = 23,
  col = "blue",
  bg = "red",
  cex = 1.5
)

dev.off()

# Figure 2: First difference
png(
  "figures/02_first_difference.png",
  width = 1600,
  height = 1000,
  res = 160
)

plot(
  mydata$diff1,
  type = "l",
  col = "red",
  ylim = c(-70, 70),
  main = "First-Differenced Sugarcane Production",
  ylab = "Change in production (million tonnes)",
  xlab = "Year",
  xaxt = "n"
)

axis(
  side = 1,
  at = seq(1951, 2011, by = 10),
  labels = seq(1951, 2011, by = 10)
)

points(
  mydata$diff1,
  pch = 19,
  col = "blue",
  cex = 0.5
)

grid()
abline(h = 0)

dev.off()

# Figure 3: Forecast
png(
  "figures/03_forecast.png",
  width = 1600,
  height = 1000,
  res = 160
)

plot(
  forecast_210,
  xlim = c(1951, 2017),
  ylim = c(0, 400),
  fcol = 10,
  xlab = "Year",
  ylab = "Production (million tonnes)",
  main = "Forecasts from ARIMA(2,1,0)"
)

dev.off()

# Figure 4: Observed vs fitted
png(
  "figures/04_observed_vs_fitted.png",
  width = 1600,
  height = 1000,
  res = 160
)

old_mar <- par("mar")
par(mar = c(7, 4, 2, 2))

plot(
  mydata$Production,
  type = "n",
  ann = FALSE,
  ylim = c(0, 400),
  xaxt = "n"
)

usr <- par("usr")

rect(
  usr[1],
  usr[3],
  usr[2],
  usr[4],
  col = "grey95",
  border = NA
)

lines(
  mydata$Production,
  col = "red"
)

lines(
  forecast_210$fitted,
  col = "green"
)

axis(
  side = 1,
  at = seq(1951, 2011, by = 2),
  labels = seq(1951, 2011, by = 2),
  las = 2,
  cex.axis = 0.7
)

box()

title(
  main = "Sugarcane Production Fitted with ARIMA(2,1,0) Model",
  cex.main = 0.9
)

legend(
  x = "topleft",
  c("Observed", "Fit"),
  col = c("red", "green"),
  lty = 1,
  lwd = 1
)

par(mar = old_mar)
dev.off()

# Figure 5: Standardized residuals
png(
  "figures/05_standardized_residuals.png",
  width = 1600,
  height = 1000,
  res = 160
)

plot(
  standardized_residuals,
  col = "black",
  ylab = "Standardized Residual",
  xlab = "Year",
  type = "h",
  main = "Standardized Residuals from ARIMA(2,1,0)"
)

abline(h = 0)

dev.off()

# Figure 6: Q-Q plot
png(
  "figures/06_qq_plot.png",
  width = 1600,
  height = 1000,
  res = 160
)

qqnorm(
  residuals_model1,
  pch = 1,
  frame = TRUE,
  ylab = "Residuals",
  main = "Normal Q-Q Plot of ARIMA(2,1,0) Residuals"
)

qqline(
  residuals_model1,
  col = "red"
)

grid(5, 5)

dev.off()

# Figure 7: Residual ACF
png(
  "figures/07_residual_acf.png",
  width = 1600,
  height = 1000,
  res = 160
)

acf(
  residuals_model1,
  lag.max = 20,
  main = "ACF of ARIMA(2,1,0) Residuals"
)

dev.off()

message(
  "Reproducible outputs generated: ",
  "4 result tables in results/ and 7 figures in figures/."
)
