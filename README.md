# Dimensionality Reduction of Indian Air Quality Data Using PCA

**Module:** Multivariate Modelling (MSc Data Science, Semester 2)  
**Author:** Rishikesh Mahendra Dharane  
**Institution:** Munster Technological University  
**Date:** April 2026

---

## Project Overview

This project applies **Principal Component Analysis (PCA)** to 17 continuous air quality and meteorological variables recorded across Indian cities. The goal is to identify the latent structure underlying these variables and determine whether the resulting low-dimensional representation captures meaningful pollution patterns aligned with established Air Quality Index (AQI) categories.

A **K-Means clustering** extension is included as a second multivariate method to validate the PCA results without using any labels.

---

## Three Key Findings

1. **PCA finds hidden structure** — 17 variables reduced to 5 interpretable components explaining 71.5% of total variance. Each component maps to a real atmospheric phenomenon (combustion load, moisture vs ozone, convective activity, geography, dust vs aerosol).

2. **Standardisation is not optional** — sensitivity analysis showed that unscaled PCA placed 91.3% of variance into PC1 (dominated by CO whose SD = 377), versus a balanced 29.5% under z-score standardisation. Mixed-unit datasets must be standardised before PCA.

3. **K-Means confirms it** — unsupervised clustering on PC scores (no labels provided) spontaneously recovered the AQI pollution bands. Cluster 1 was 39% Very Unhealthy; Cluster 4 was 66% Unhealthy. Between-SS/Total-SS = 54.1%.

---

## Repository Structure

```
aqi-pca-project/
│
├── aqi_india_38cols_knn_final.csv   # Dataset (download from Kaggle — see below)
├── aqi_pca_analysis.R               # Full R analysis script
├── aqi_pca_report.pdf               # Compiled report (PDF)
├── aqi_pca_report.tex               # LaTeX source for the report
├── AQI_PCA_Presentation.pptx        # Presentation slides with speaker notes
├── README.md                        # This file
│
└── figures/
    ├── Figure1.png                  # Correlation heatmap
    ├── Figure2.png                  # Scree plot
    ├── Figure3.png                  # Variable loading plot
    ├── Figure4.png                  # PCA score plot
    └── Figure5.png                  # K-Means elbow plot
```

---

## Dataset

| Property | Value |
|---|---|
| Source | [Kaggle — Indian Air Quality Index Dataset](https://www.kaggle.com/) |
| Raw size | 842,160 rows × 31 columns |
| Period | 2022–2024 (hourly observations) |
| Pre-processing | KNN imputation applied by dataset author (zero NAs) |
| Working sample | 50,000 rows (random, `set.seed(42)`) |

### Why sampled to 50,000 rows?

The full 842,160-row dataset requires approximately **26 GB of RAM** for the PCA matrix decomposition. A random sample of 50,000 rows is statistically more than sufficient — PCA results stabilise well below 10,000 observations for a 17-variable dataset. The sensitivity analysis confirmed the eigenvalue pattern was stable.

### Variables used (17 continuous)

| Group | Variables |
|---|---|
| Pollutants | pm2_5_ugm3, pm10_ugm3, co_ugm3, no2_ugm3, so2_ugm3, o3_ugm3, dust_ugm3, aod, us_aqi |
| Meteorology | humidity_percent, dew_point_c, wind_gusts_kmh, precipitation_mm, pressure_msl_hpa, cloud_cover_percent |
| Geography | latitude, longitude |

**Excluded:** categorical columns (city, state, season, aqi_category), binary flags (is_weekend, is_raining, heavy_rain), and the datetime column — none of these are appropriate inputs for PCA.

---

## Requirements

### R version
```
R >= 4.4.0
```

### Packages
```r
install.packages(c(
  "tidyverse",    # data wrangling
  "janitor",      # clean column names
  "corrplot",     # correlation heatmap
  "psych",        # KMO and Bartlett's test
  "FactoMineR",   # PCA engine
  "factoextra"    # PCA visualisation
))
```

> **Note:** If you get `namespace 'rlang' X.X.X is already loaded, but >= X.X.X is required`, run `install.packages("rlang")` and then **restart your R session completely** before loading any libraries. Simply reinstalling without restarting will not work because the old namespace is already in memory.

---

## How to Run

1. **Download the dataset** from Kaggle and place it in the same directory as `aqi_pca_analysis.R`.

2. **Open** `aqi_pca_analysis.R` in RStudio.

3. **Set your working directory** to the project folder:
```r
setwd("path/to/aqi-pca-project")
```

4. **Run the script** from top to bottom in one go. Do not run sections in isolation — variables from earlier sections are needed by later ones.

> **Important:** Always restart R (`Session → Restart R` in RStudio, or Ctrl+Shift+F10) before running the full script. Running it twice in the same session without restarting can cause `df` to be overwritten back to 842K rows, which will trigger the memory error.

---

## Script Structure

| Section | What it does |
|---|---|
| Section 0 | Load libraries |
| Section 1 | Load CSV, clean names, sample to 50,000 rows |
| Section 2 | Select 17 continuous variables, check for NAs, print descriptive statistics and SDs |
| Section 3 | Correlation heatmap (Figure 1), Bartlett's test, KMO test |
| Section 4 | Run PCA, get eigenvalues, apply Kaiser criterion and 70% threshold, scree plot (Figure 2) |
| Section 5 | Print loading matrix, variable loading plot (Figure 3), score plot (Figure 4) |
| Section 6 | K-Means elbow plot (Figure 5), run K-Means k=5, cross-tabulate clusters vs AQI labels |
| Section 7 | Sensitivity analysis — unscaled PCA vs scaled PCA, PCA without us_aqi |
| Section 8 | sessionInfo() for reproducibility |

---

## Key Results

### Eigenvalues

| Component | Eigenvalue | % Variance | Cumulative % |
|---|---|---|---|
| PC1 | 5.012 | 29.5% | 29.5% |
| PC2 | 2.459 | 14.5% | 43.9% |
| PC3 | 2.129 | 12.5% | 56.5% |
| PC4 | 1.413 | 8.3%  | 64.8% |
| PC5 | 1.148 | 6.8%  | 71.5% |

**5 components retained** — agreed by both Kaiser criterion (eigenvalue > 1) and 70% cumulative variance threshold.

### Component Interpretations

| Component | Interpretation | Key Variables |
|---|---|---|
| PC1 | Combustion Pollution Load | PM2.5 (0.918), PM10 (0.857), CO (0.802), NO2 (0.719), SO2 (0.687) |
| PC2 | Moisture vs Ozone | Humidity (0.822), Dew Point (0.535) vs O3 (−0.719), Wind (−0.417) |
| PC3 | Convective Activity | Dew Point (0.626), Wind (0.474), Pressure (−0.677) |
| PC4 | Geographic Location | Latitude (0.635), Longitude (0.644) |
| PC5 | Dust vs Fine Aerosol | Dust (−0.636) vs AOD (0.455), O3 (0.432) |

### Suitability Tests

| Test | Result | Interpretation |
|---|---|---|
| Bartlett's Sphericity | χ²(136) = 9,803,231, p < 0.001 | Variables are significantly correlated — PCA appropriate |
| KMO Overall MSA | 0.70 | Meritorious — above 0.60 threshold |

### Sensitivity Analysis

| Model | PC1 % Variance |
|---|---|
| Unscaled PCA (no standardisation) | **91.3%** — dominated by CO |
| Scaled PCA (z-score, used in analysis) | **29.5%** — balanced and interpretable |
| PCA without us_aqi composite | 26.99% — stable, confirms results not driven by index |

---

## Known Issues and Fixes

### Memory error: `cannot allocate vector of size 26.4 Gb`
The full dataset is too large for PCA on a standard laptop. The script handles this by sampling 50,000 rows at the start. If you still get this error, ensure `df <- df %>% slice_sample(n = 50000)` runs before `df_numeric` is created. Restart R and run from Section 0.

### `namespace 'rlang' X.X is already loaded`
Run `install.packages("rlang")` then restart R completely before running the script.

### `$ operator is invalid for atomic vectors`
This happens if `get_eigenvalue()` result is not converted to a data frame. The script uses `eigenvalues <- as.data.frame(get_eigenvalue(res.pca))` to prevent this.

### RStudio graphics error 4 / slow plots
The score plot and cluster plot use a 5,000-row sample for rendering only. The PCA and K-Means are computed on the full working dataset. Do not attempt to plot all rows — RStudio will freeze.

---

## Compiling the LaTeX Report

The report source is `aqi_pca_report.tex`. To compile on your machine:

1. Install a LaTeX distribution: [TeX Live](https://tug.org/texlive/) (Linux/Mac) or [MiKTeX](https://miktex.org/) (Windows).
2. Place `Figure1.png` through `Figure5.png` in the same directory as the `.tex` file.
3. Compile twice (needed for table of contents cross-references):
```bash
pdflatex aqi_pca_report.tex
pdflatex aqi_pca_report.tex
```

On Overleaf: upload the `.tex` file and all five figure PNGs, then click **Recompile**.

---

## References

- Jolliffe, I.T. (2002). *Principal Component Analysis*, 2nd edn. Springer.
- Lê, S., Josse, J. and Husson, F. (2008). FactoMineR: An R Package for Multivariate Analysis. *Journal of Statistical Software*, 25(1), pp. 1–18.
- Kassambara, A. and Mundt, F. (2017). *factoextra: Extract and Visualize the Results of Multivariate Data Analyses*. R package version 1.0.5.
- Kaiser, H.F. (1974). An index of factorial simplicity. *Psychometrika*, 39(1), pp. 31–36.
- Bartlett, M.S. (1951). The effect of standardization on a chi-square approximation in factor analysis. *Biometrika*, 38(3–4), pp. 337–344.

---

## Academic Integrity

This project was completed for the Multivariate Modelling module at Munster Technological University. The dataset was not used in any prior academic submission. Generative AI tools were used to support coding and writing; all methodology, interpretation, and code are understood and can be explained independently.
