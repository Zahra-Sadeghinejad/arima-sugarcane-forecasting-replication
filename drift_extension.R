# Drift Extension
# -------------------------------------------------------------------------
# This file is intentionally separate from the core 2023 replication.
#
# Run interactively after:
#   source("analysis.R")
#
# save_outputs.R sources this file automatically after analysis.R.
# -------------------------------------------------------------------------

required_objects <- c("mydata", "model1", "forecast_210")

missing_objects <- required_objects[
  !vapply(required_objects, exists, logical(1))
]

if (length(missing_objects) > 0) {
  stop(
    "Run source(\"analysis.R\") before drift_extension.R. Missing: ",
    paste(missing_objects, collapse = ", ")
  )
}

# -------------------------------------------------------------------------
# 1. Estimate the same ARIMA order with drift
# -------------------------------------------------------------------------

model1_drift <- forecast::Arima(
  mydata$Production,
  order = c(2, 1, 0),
  include.drift = TRUE,
  method = "ML"
)

forecast_210_drift <- forecast::forecast(
  model1_drift,
  h = 5,
  level = c(80, 95, 99.5)
)

# -------------------------------------------------------------------------
# 2. Reconstruct the paper's stated forecasting equation
# -------------------------------------------------------------------------

manual_ar2_mean_forecast <- function(y, phi1, phi2, mu, h = 5) {

  differences <- diff(as.numeric(y))

  previous_1 <- tail(differences, 1)
  previous_2 <- tail(differences, 2)[1]

  predicted_differences <- numeric(h)

  for (i in seq_len(h)) {

    next_difference <- mu +
      phi1 * (previous_1 - mu) +
      phi2 * (previous_2 - mu)

    predicted_differences[i] <- next_difference

    previous_2 <- previous_1
    previous_1 <- next_difference
  }

  tail(as.numeric(y), 1) + cumsum(predicted_differences)
}

published_forecast <- c(
  350.489,
  322.601,
  325.031,
  344.502,
  350.250
)

paper_equation_forecast <- manual_ar2_mean_forecast(
  mydata$Production,
  phi1 = 0.3783,
  phi2 = -0.6652,
  mu = 5.13,
  h = 5
)

# -------------------------------------------------------------------------
# 3. Compare model specifications
# -------------------------------------------------------------------------

drift_model_comparison <- data.frame(
  Specification = c(
    "ARIMA(2,1,0) without drift",
    "ARIMA(2,1,0) with drift"
  ),
  AR1 = round(c(
    unname(coef(model1)["ar1"]),
    unname(coef(model1_drift)["ar1"])
  ), 6),
  AR2 = round(c(
    unname(coef(model1)["ar2"]),
    unname(coef(model1_drift)["ar2"])
  ), 6),
  Drift = round(c(
    NA,
    unname(coef(model1_drift)["drift"])
  ), 6),
  Sigma2 = round(c(
    model1$sigma2,
    model1_drift$sigma2
  ), 6),
  LogLik = round(c(
    as.numeric(logLik(model1)),
    as.numeric(logLik(model1_drift))
  ), 6),
  AIC = round(c(
    AIC(model1),
    AIC(model1_drift)
  ), 6),
  AICc = round(c(
    model1$aicc,
    model1_drift$aicc
  ), 6),
  BIC = round(c(
    BIC(model1),
    BIC(model1_drift)
  ), 6)
)

# -------------------------------------------------------------------------
# 4. Compare forecast paths
# -------------------------------------------------------------------------

replication_forecast <- as.numeric(forecast_210$mean)
drift_forecast <- as.numeric(forecast_210_drift$mean)

drift_forecast_comparison <- data.frame(
  Year = 2013:2017,
  Published_Forecast = published_forecast,
  Replication_No_Drift = round(replication_forecast, 6),
  Estimated_Drift = round(drift_forecast, 6),
  Paper_Stated_Equation = round(paper_equation_forecast, 6),
  Abs_Error_No_Drift = round(
    abs(replication_forecast - published_forecast),
    6
  ),
  Abs_Error_Drift = round(
    abs(drift_forecast - published_forecast),
    6
  ),
  Abs_Error_Paper_Equation = round(
    abs(paper_equation_forecast - published_forecast),
    6
  )
)

drift_mae <- data.frame(
  Specification = c(
    "Replication without drift",
    "Estimated drift",
    "Paper stated equation"
  ),
  MAE_vs_Published = round(c(
    mean(abs(replication_forecast - published_forecast)),
    mean(abs(drift_forecast - published_forecast)),
    mean(abs(paper_equation_forecast - published_forecast))
  ), 6)
)

cat("\n====================================================\n")
cat("Extension: Testing a Drift Specification\n")
cat("====================================================\n\n")

print(model1_drift)

cat("\nModel comparison:\n")
print(drift_model_comparison, row.names = FALSE)

cat("\nMean first difference:\n")
print(mean(diff(mydata$Production)))

cat("\nForecast-path comparison:\n")
print(drift_forecast_comparison, row.names = FALSE)

cat("\nMAE relative to the published forecast path:\n")
print(drift_mae, row.names = FALSE)
