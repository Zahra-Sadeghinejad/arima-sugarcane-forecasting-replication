# adf_helpers.R
# Independent helper used for the public replication repository.
#
# Purpose:
# Reproduce the ADF-OLS test with BIC lag selection used in the
# original 2023 coursework, without redistributing the third-party
# course script.
#
# The implementation follows the econometric procedure used in the
# original project:
#   1. GLS-detrend the series for lag-order selection.
#   2. Select the number of augmentation lags by BIC.
#   3. Estimate the ADF regression by OLS on the original series.
#
# Supported deterministic specifications:
#   trend = "c"  : constant
#   trend = "ct" : constant + linear trend


.lag_with_zeros <- function(x, lag) {
  if (lag == 0) {
    return(x)
  }

  c(rep(0, lag), x[seq_len(length(x) - lag)])
}


.gls_detrend <- function(y, trend) {
  n <- length(y)

  if (trend == "c") {
    z <- matrix(1, nrow = n, ncol = 1)
    c_bar <- -7
  } else {
    z <- cbind(
      constant = 1,
      trend = seq_len(n)
    )
    c_bar <- -13.5
  }

  alpha_bar <- 1 + c_bar / n

  y_star <- c(
    y[1],
    y[-1] - alpha_bar * y[-n]
  )

  z_star <- rbind(
    z[1, , drop = FALSE],
    z[-1, , drop = FALSE] -
      alpha_bar * z[-n, , drop = FALSE]
  )

  beta_gls <- solve(
    crossprod(z_star),
    crossprod(z_star, y_star)
  )

  y_gls <- y - drop(z %*% beta_gls)

  list(
    y_gls = y_gls,
    z = z
  )
}


.select_bic_lag <- function(y_gls, kmax, kmin = 0) {
  n <- length(y_gls)
  dy <- c(0, diff(y_gls))

  design <- matrix(
    .lag_with_zeros(y_gls, 1),
    ncol = 1
  )

  if (kmax > 0) {
    for (lag in seq_len(kmax)) {
      design <- cbind(
        design,
        .lag_with_zeros(dy, lag)
      )
    }
  }

  # Use one common effective sample for every candidate lag order.
  keep <- seq.int(kmax + 2, n)
  target <- dy[keep]
  design <- design[keep, , drop = FALSE]

  n_eff <- length(target)
  bic <- rep(Inf, kmax + 1)

  for (k in kmin:kmax) {
    x <- design[, seq_len(k + 1), drop = FALSE]

    beta <- solve(
      crossprod(x),
      crossprod(x, target)
    )

    residuals <- target - drop(x %*% beta)
    sigma2 <- sum(residuals^2) / n_eff

    bic[k + 1] <-
      log(sigma2) +
      log(n_eff) * k / n_eff
  }

  which.min(bic) - 1
}


.adf_ols_statistic <- function(y, z, k) {
  n <- length(y)
  dy <- c(0, diff(y))

  design <- cbind(
    lagged_level = .lag_with_zeros(y, 1),
    z
  )

  if (k > 0) {
    for (lag in seq_len(k)) {
      design <- cbind(
        design,
        .lag_with_zeros(dy, lag)
      )
    }
  }

  keep <- seq.int(k + 2, n)
  target <- dy[keep]
  design <- design[keep, , drop = FALSE]

  beta <- solve(
    crossprod(design),
    crossprod(design, target)
  )

  residuals <- target - drop(design %*% beta)

  residual_df <-
    length(target) -
    (k + 1 + ncol(z))

  sigma2 <- sum(residuals^2) / residual_df
  xtx_inv <- solve(crossprod(design))

  standard_error <-
    sqrt(xtx_inv[1, 1] * sigma2)

  as.numeric(beta[1] / standard_error)
}


adf_bic_test <- function(
  y,
  trend = c("c", "ct"),
  kmax = NULL,
  kmin = 0
) {
  trend <- match.arg(trend)
  y <- as.numeric(y)

  if (anyNA(y)) {
    stop("The input series contains missing values.")
  }

  n <- length(y)

  if (n < 10) {
    stop("The input series is too short for this ADF implementation.")
  }

  if (is.null(kmax)) {
    kmax <- floor(12 * (n / 100)^0.25)
  }

  if (
    kmin < 0 ||
    kmax < 0 ||
    kmin > kmax ||
    kmax >= n - 2
  ) {
    stop("Invalid lag bounds.")
  }

  detrended <- .gls_detrend(y, trend)
  y_gls <- detrended$y_gls
  z <- detrended$z

  selected_lag <- .select_bic_lag(
    y_gls = y_gls,
    kmax = kmax,
    kmin = kmin
  )

  statistic <- .adf_ols_statistic(
    y = y,
    z = z,
    k = selected_lag
  )

  phi <- sum(
    y_gls[-n] * y_gls[-1]
  ) / sum(
    y_gls[-n]^2
  )

  critical_values <- if (trend == "c") {
    c(`1%` = -3.43, `5%` = -2.86, `10%` = -2.57)
  } else {
    c(`1%` = -3.96, `5%` = -3.41, `10%` = -3.13)
  }

  result <- list(
    method = "ADF-OLS",
    stat = statistic,
    cv = critical_values,
    penalty = "BIC",
    k = selected_lag,
    phi = as.numeric(phi),
    trend = trend,
    kmax = kmax
  )

  class(result) <- "adf_bic_test"
  result
}


print.adf_bic_test <- function(x, ...) {
  cat("\nAugmented Dickey-Fuller Test (ADF-OLS)\n")
  cat("Null hypothesis: unit root\n")
  cat(sprintf("Test statistic: %.3f\n", x$stat))
  cat(
    sprintf(
      "Critical values (1%%, 5%%, 10%%): %.2f %.2f %.2f\n",
      x$cv[1],
      x$cv[2],
      x$cv[3]
    )
  )
  cat(sprintf("Lag selection: %s\n", x$penalty))
  cat(sprintf("Selected lag: %d\n", x$k))
  cat(sprintf("Estimated AR coefficient after GLS detrending: %.4f\n\n", x$phi))

  invisible(x)
}
