# ARIMA Time-Series Forecasting Replication in R

A replication and reproducibility project based on:

**Kumar, Manoj & Anand, Madhu — “An Application of Time Series ARIMA Forecasting Model for Predicting Sugarcane Production in India.”**

This project reproduces the main ARIMA forecasting workflow using annual sugarcane production data for India from crop years 1950–51 to 2011–12.

The analysis covers data preparation, stationarity testing, model identification, ARIMA estimation and comparison, five-year forecasting, and residual diagnostics.

The original replication was completed as a Financial Time Series project in 2023 and has since been reorganized and documented for reproducibility.

---

## Project Objectives

- Reconstruct the historical sugarcane production series used in the study.
- Test the series for stationarity using Augmented Dickey-Fuller tests.
- Apply first differencing to address non-stationarity.
- Use ACF and PACF to guide ARIMA model identification.
- Estimate and compare ARIMA(2,1,0), ARIMA(2,1,1), and ARIMA(2,1,2).
- Select the preferred model using AIC, AICc, and BIC.
- Generate five-year forecasts for 2013–2017.
- Evaluate model adequacy using residual diagnostics and autocorrelation tests.
- Compare the reproduced results with those reported in the original study.

---

## Key Result

Among the three candidate specifications, **ARIMA(2,1,0)** produces the lowest AIC, AICc, and BIC and is therefore selected as the preferred model.

Residual diagnostics and formal autocorrelation tests provide no evidence of significant remaining serial correlation.

---

## Data

The dataset contains annual sugarcane production in India for 62 crop years, from 1950–51 to 2011–12, measured in million tonnes.

For the R time-series analysis, each crop year is represented by its ending calendar year:

- 1950–51 → 1951
- 1951–52 → 1952
- ...
- 2011–12 → 2012

The dataset used in the analysis is available in:

[`data/production.csv`](data/production.csv)

### Historical Production Series

![Sugarcane production in India](figures/01_original_series.png)

The production series shows a strong long-run upward movement, indicating that stationarity should be examined before fitting an ARIMA model.

### First Differencing

The analysis applies first differencing:

$$
\Delta y_t = y_t - y_{t-1}
$$

![First-differenced sugarcane production](figures/02_first_difference.png)

After differencing, the series fluctuates around a substantially more stable mean.

---

## Methodology

The replication follows a Box–Jenkins ARIMA modelling workflow:

1. Visual inspection of the original production series.
2. Stationarity testing using Augmented Dickey-Fuller (ADF) tests.
3. First differencing of the level series.
4. ACF and PACF analysis to guide model identification.
5. Maximum-likelihood estimation of three candidate models:
   - ARIMA(2,1,0)
   - ARIMA(2,1,1)
   - ARIMA(2,1,2)
6. Model comparison using AIC, AICc, and BIC.
7. Five-step-ahead forecasting for 2013–2017.
8. Residual diagnostics, including:
   - residual plots
   - Q-Q analysis
   - residual ACF/PACF
   - Ljung–Box test
   - Box–Pierce test

The original 2023 coursework used custom unit-root functions supplied as course material. For this public repository, the required procedure was independently implemented in `adf_helpers.R`, reproducing the original project results. The implementation follows three steps:

1. GLS-detrend the series for lag-order selection.
2. Select the number of augmentation lags using BIC.
3. Estimate the final ADF regression by OLS on the original series.

Accordingly, the shorthand `ADF-OLS + BIC` used in the results tables refers to an OLS ADF test whose augmentation lag is selected by BIC on the GLS-detrended series.

An additional ADF test is performed using the `tseries` package as a supplementary stationarity check.

---

## Stationarity Results

The ADF test fails to reject a unit root in the level series but strongly rejects the unit-root null after first differencing. This supports using an integration order of **d = 1**.

| Series | Test | Test Statistic | Lag | 5% Critical Value | Conclusion |
|---|---|---:|---:|---:|---|
| Level | ADF-OLS + BIC | -2.964 | 2 | -3.41 | Fail to reject unit root |
| First difference | ADF-OLS + BIC | -11.694 | 1 | -2.86 | Reject unit root |
| First difference | ADF – `tseries` | -5.299 | 3 | — | Reject unit root, p < 0.01 |

For the level series, the ADF statistic of -2.964 is less negative than the 5% critical value of -3.41, so the unit-root null hypothesis is not rejected.

After first differencing, the ADF statistic falls to -11.694, well below the 5% critical value of -2.86, providing strong evidence against a unit root.

The additional `tseries` ADF test reaches the same conclusion with p < 0.01.

The complete results are available in:

[`results/stationarity_tests.csv`](results/stationarity_tests.csv)

---

## Model Identification and Selection

The ACF and PACF of the first-differenced series were examined to guide model identification.

![ACF and PACF of the first-differenced series](figures/08_acf_pacf_first_difference.png)

The PACF contains a particularly strong spike at lag 2, supporting the consideration of two autoregressive terms.

Three candidate specifications were estimated:

- ARIMA(2,1,0)
- ARIMA(2,1,1)
- ARIMA(2,1,2)

All models were estimated using maximum likelihood.

### Model Comparison

| Model | AIC | AICc | BIC |
|---|---:|---:|---:|
| ARIMA(2,1,0) | 519.70 | 520.12 | 526.03 |
| ARIMA(2,1,1) | 521.45 | 522.16 | 529.89 |
| ARIMA(2,1,2) | 523.17 | 524.26 | 533.73 |

ARIMA(2,1,0) has the lowest AIC, AICc, and BIC across all three candidate specifications and is therefore selected as the preferred model.

### Selected Model Estimates

| Parameter | Estimate | Standard Error |
|---|---:|---:|
| AR(1) | 0.3336 | 0.0962 |
| AR(2) | -0.6635 | 0.0964 |

Additional model statistics:

- Estimated innovation variance: 269.6
- Log-likelihood: -256.85
- AIC: 519.70
- AICc: 520.12
- BIC: 526.03

The complete model-comparison results are available in:

[`results/model_comparison.csv`](results/model_comparison.csv)

---

## Forecast Results: 2013–2017

Using the selected ARIMA(2,1,0) model, five-step-ahead forecasts were generated for 2013–2017.

![ARIMA forecast](figures/03_forecast.png)

| Year | Point Forecast | 80% Interval | 95% Interval | 99.5% Interval |
|---|---:|---:|---:|---:|
| 2013 | 312.12 | 291.07 – 333.16 | 279.93 – 344.30 | 266.03 – 358.21 |
| 2014 | 300.07 | 265.00 – 335.15 | 246.43 – 353.72 | 223.24 – 376.91 |
| 2015 | 316.01 | 277.27 – 354.75 | 256.77 – 375.26 | 231.16 – 400.87 |
| 2016 | 329.32 | 289.79 – 368.86 | 268.85 – 389.79 | 242.72 – 415.93 |
| 2017 | 323.19 | 281.64 – 364.74 | 259.64 – 386.73 | 232.18 – 414.20 |

The point forecasts remain around 300–330 million tonnes over the forecast horizon, while the prediction intervals widen as uncertainty increases further into the future.

The forecast plot retains the replication's vertical scale of 0–400 million tonnes for consistency with the original study. This means that the upper 99.5% prediction interval is visually clipped for some later forecast years; the complete interval values are reported in the table above.

The full forecast output is available in:

[`results/forecasts_2013_2017.csv`](results/forecasts_2013_2017.csv)

### Observed vs. Fitted Values

![Observed versus fitted values](figures/04_observed_vs_fitted.png)

The fitted series captures the broad movement of the observed production data while smoothing some of the year-to-year variation.

---

## Residual Diagnostics

Residual diagnostics were used to assess whether the selected ARIMA(2,1,0) model left substantial systematic structure unexplained.

### Standardized Residuals

![Standardized residuals](figures/05_standardized_residuals.png)

Residuals were additionally scaled by the estimated innovation standard deviation:

$$
e_t^{*} = \frac{e_t}{\sqrt{\hat{\sigma}^{2}}}
$$

The standardized-residual plot was added during the reproducibility cleanup of the original project. The original 2023 script plotted raw residuals under a "Standardized Residuals" title; the reorganized version distinguishes raw and scaled residuals explicitly.

### Normality Check

![Normal Q-Q plot](figures/06_qq_plot.png)

The Q-Q plot provides a visual diagnostic of how closely the residual distribution resembles a normal distribution. It is used here as a diagnostic rather than as a formal normality test.

### Residual Autocorrelation

![Residual ACF](figures/07_residual_acf.png)

The residual ACF is used to examine whether meaningful serial dependence remains after fitting the model.

Formal residual autocorrelation tests are reported under three specifications:

| Specification | Lag | `fitdf` | Ljung–Box p-value | Box–Pierce p-value |
|---|---:|---:|---:|---:|
| Conventional ARIMA adjustment | 20 | 2 | 0.8397 | 0.9244 |
| Paper-style comparison | 20 | 0 | 0.9110 | 0.9639 |
| Original 2023 coursework | 25 | 5 | 0.8290 | 0.9359 |

The **conventional ARIMA adjustment** uses `fitdf = p + q = 2` for the ARIMA(2,1,0) model and is treated as the primary residual autocorrelation check.

The **paper-style comparison** uses 20 lags without a parameter adjustment. This produces 20 degrees of freedom, matching the degrees of freedom reported in the original paper. However, several combinations of `lag` and `fitdf` can produce 20 degrees of freedom, so the paper's exact diagnostic configuration cannot be identified from the published output alone.

The **original 2023 coursework** used `lag = 25` and `fitdf = 5`. These settings are preserved as a historical replication record rather than as the preferred diagnostic specification.

Twenty lags is relatively high for a sample of 62 annual observations. It is retained in the first two specifications to facilitate comparison with the published analysis rather than because it is uniquely preferred for this sample.

All three specifications lead to the same qualitative conclusion: at conventional significance levels, there is no evidence of significant remaining residual autocorrelation.

Importantly, using the paper-style lag and degrees-of-freedom configuration does not reproduce the paper's reported test statistics exactly. The residual-diagnostic discrepancy therefore cannot be explained by the `lag`/`fitdf` choice alone.

The complete test results are available in:

[`results/residual_autocorrelation_tests.csv`](results/residual_autocorrelation_tests.csv)

---

## Replication Notes

The replication reproduces the central model-selection result of the original study:

> ARIMA(2,1,0) is preferred to ARIMA(2,1,1) and ARIMA(2,1,2).

However, the exact numerical estimates obtained in the replication are not identical to those reported in the published paper.

### Selected Model Comparison

| Result | Original Paper | Replication |
|---|---:|---:|
| AR(1) | 0.3783 | 0.3336 |
| AR(2) | -0.6652 | -0.6635 |
| Innovation variance | 265.4 | 269.6 |
| Log-likelihood | -257.39 | -256.85 |
| AIC | 520.78 | 519.70 |
| AICc | 521.20 | 520.12 |
| BIC | 527.11 | 526.03 |

Despite these numerical differences, both analyses select ARIMA(2,1,0) as the preferred specification.

### Forecast Comparison

| Year | Original Paper | Replication |
|---|---:|---:|
| 2013 | 350.49 | 312.12 |
| 2014 | 322.60 | 300.07 |
| 2015 | 325.03 | 316.01 |
| 2016 | 344.50 | 329.32 |
| 2017 | 350.25 | 323.19 |

The purpose of this repository is to provide a transparent and reproducible implementation of the published workflow, rather than to manually adjust the reproduced output to match the paper.

The residual autocorrelation statistics also differ numerically, while both analyses reach the same qualitative conclusion that there is no strong evidence of remaining residual autocorrelation.

Possible sources of numerical differences include software versions, package implementations, and other implementation details. The repository reports the results generated directly by the documented R code.

---

## Repository Structure

```text
arima-sugarcane-replication/
├── analysis.R
├── plots.R
├── adf_helpers.R
├── save_outputs.R
├── README.md
│
├── data/
│   └── production.csv
│
├── figures/
│   ├── 01_original_series.png
│   ├── 02_first_difference.png
│   ├── 03_forecast.png
│   ├── 04_observed_vs_fitted.png
│   ├── 05_standardized_residuals.png
│   ├── 06_qq_plot.png
│   ├── 07_residual_acf.png
│   └── 08_acf_pacf_first_difference.png
│
└── results/
    ├── model_comparison.csv
    ├── forecasts_2013_2017.csv
    ├── residual_autocorrelation_tests.csv
    └── stationarity_tests.csv
```

---

## How to Reproduce

### 1. Clone the repository

```bash
git clone https://github.com/Zahra-Sadeghinejad/arima-sugarcane-forecasting-replication.git
cd arima-sugarcane-forecasting-replication
```

Open the repository folder in R or RStudio and use the repository root as the working directory.

### 2. Install the required packages

```r
install.packages(c("forecast", "tseries"))
```

The replication was rerun using:

- R 4.4.1
- `forecast` 9.0.2
- `tseries` 0.10-60

### 3. Run the statistical analysis

For an interactive run of the analysis in R or RStudio:

```r
source("analysis.R")
```

This reproduces the statistical workflow and prints the main model estimates, forecasts, and diagnostics.

### 4. Reproduce the committed outputs

To regenerate all committed output files — including the four result tables and eight figures — run from the repository root:

```bash
Rscript save_outputs.R
```

`save_outputs.R` runs the full analysis and regenerates the contents of `results/` and `figures/` using relative paths. No user-specific directory paths are required.

A successful run ends with:

```text
Reproducible outputs generated: 4 result tables in results/ and 8 figures in figures/.
```

---

## Skills Demonstrated

- Time-series data preparation in R
- Stationarity testing with Augmented Dickey-Fuller tests
- ARIMA model identification using ACF and PACF
- Maximum-likelihood model estimation
- Model comparison using AIC, AICc, and BIC
- Multi-step forecasting with prediction intervals
- Residual and model-diagnostic analysis
- Reproducible analytical workflow
- Automated regeneration of analysis outputs
- Comparison of reproduced and published results
- Documentation of replication discrepancies

---

## Tools

- R
- `forecast`
- `tseries`
- Git / GitHub
- ARIMA / Box–Jenkins modelling
- ADF stationarity testing
- ACF / PACF diagnostics
- Ljung–Box and Box–Pierce tests

---

## Attribution

Original study:

> Kumar, Manoj & Anand, Madhu. *An Application of Time Series ARIMA Forecasting Model for Predicting Sugarcane Production in India.*

[View the paper on ResearchGate](https://www.researchgate.net/publication/263505554_An_Application_Of_Time_Series_Arima_Forecasting_Model_For_Predicting_Sugarcane_Production_In_India)

The original article is not redistributed in this repository.

---

## Author

**Zahra Sadeghinejad**  
MSc Economics, University of Amsterdam