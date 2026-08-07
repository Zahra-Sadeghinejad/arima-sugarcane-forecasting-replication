# save_outputs.R
# Reproduce the committed result tables and selected figures.
#
# Run from the repository root:
#   source("save_outputs.R")
#
# This script sources analysis.R, then regenerates:
#   - 4 CSV files in results/
#   - 8 PNG files in figures/

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

# The plotting functions are defined in plots.R and are also used by
# analysis.R, providing a single source of truth for interactive and
# committed figures.

# Figure 1: Original series
png(
  "figures/01_original_series.png",
  width = 1600,
  height = 1000,
  res = 160
)
plot_original_series(mydata$Production)
dev.off()

# Figure 2: First difference
png(
  "figures/02_first_difference.png",
  width = 1600,
  height = 1000,
  res = 160
)
plot_first_difference(mydata$diff1)
dev.off()

# Figure 3: Forecast
png(
  "figures/03_forecast.png",
  width = 1600,
  height = 1000,
  res = 160
)
plot_forecast_210(forecast_210)
dev.off()

# Figure 4: Observed vs fitted
png(
  "figures/04_observed_vs_fitted.png",
  width = 1600,
  height = 1000,
  res = 160
)
plot_observed_vs_fitted(
  mydata$Production,
  forecast_210$fitted
)
dev.off()

# Figure 5: Standardized residuals
png(
  "figures/05_standardized_residuals.png",
  width = 1600,
  height = 1000,
  res = 160
)
plot_standardized_residuals(standardized_residuals)
dev.off()

# Figure 6: Q-Q plot
png(
  "figures/06_qq_plot.png",
  width = 1600,
  height = 1000,
  res = 160
)
plot_residual_qq(residuals_model1)
dev.off()

# Figure 7: Residual ACF
png(
  "figures/07_residual_acf.png",
  width = 1600,
  height = 1000,
  res = 160
)
plot_residual_acf(residuals_model1)
dev.off()


# Figure 8: ACF and PACF of first-differenced series
png(
  "figures/08_acf_pacf_first_difference.png",
  width = 1800,
  height = 900,
  res = 160
)

plot_acf_pacf_first_difference(mydata$diff1)

dev.off()


message(
  "Reproducible outputs generated: ",
  "4 result tables in results/ and 8 figures in figures/."
)
