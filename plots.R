# plots.R
# Shared plotting functions for the ARIMA replication project.
#
# These functions provide a single source of truth for the seven figures
# committed in figures/. analysis.R uses the same functions interactively,
# while save_outputs.R opens PNG devices and calls them to regenerate files.

plot_original_series <- function(production) {
  plot(
    production,
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
    production,
    pch = 23,
    col = "blue",
    bg = "red",
    cex = 1.5
  )
}

plot_first_difference <- function(diff_series) {
  plot(
    diff_series,
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
    diff_series,
    pch = 19,
    col = "blue",
    cex = 0.5
  )

  grid()
  abline(h = 0)
}

plot_forecast_210 <- function(forecast_object) {
  plot(
    forecast_object,
    xlim = c(1951, 2017),
    ylim = c(0, 400),
    fcol = 10,
    xlab = "Year",
    ylab = "Production (million tonnes)",
    main = "Forecasts from ARIMA(2,1,0)"
  )
}

plot_observed_vs_fitted <- function(production, fitted_values) {
  old_mar <- par("mar")
  on.exit(par(mar = old_mar), add = TRUE)

  par(mar = c(7, 4, 2, 2))

  plot(
    production,
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
    production,
    col = "red"
  )

  lines(
    fitted_values,
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
}

plot_standardized_residuals <- function(
  standardized_residuals,
  col = "black",
  type = "h"
) {
  plot(
    standardized_residuals,
    col = col,
    ylab = "Standardized Residual",
    xlab = "Year",
    type = type,
    main = "Standardized Residuals from ARIMA(2,1,0)"
  )

  abline(h = 0)
}

plot_residual_qq <- function(residuals) {
  qqnorm(
    residuals,
    pch = 1,
    frame = TRUE,
    ylab = "Residuals",
    main = "Normal Q-Q Plot of ARIMA(2,1,0) Residuals"
  )

  qqline(
    residuals,
    col = "red"
  )

  grid(5, 5)
}

plot_residual_acf <- function(residuals) {
  acf(
    residuals,
    lag.max = 20,
    main = "ACF of ARIMA(2,1,0) Residuals"
  )
}

plot_acf_pacf_first_difference <- function(diff_series) {
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par))

  par(mfrow = c(1, 2))

  forecast::Acf(
    diff_series,
    lag.max = 20,
    ylim = c(-1, 1),
    main = "ACF: First-Differenced Series"
  )

  forecast::Pacf(
    diff_series,
    lag.max = 20,
    ylim = c(-1, 1),
    main = "PACF: First-Differenced Series"
  )
}

