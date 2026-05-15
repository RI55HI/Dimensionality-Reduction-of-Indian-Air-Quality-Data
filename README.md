# Dimensionality Reduction of Indian Air Quality Data

## 1. Project Overview
This project performs a comprehensive multivariate analysis of air quality and meteorological data across various Indian cities (2022–2024). Using **Principal Component Analysis (PCA)**, the study reduces 17 continuous variables into 5 meaningful components. As an extension, **K-Means Clustering** is applied to identify distinct environmental profiles and validate them against established Air Quality Index (AQI) categories.

## 2. Dataset Description
- **Source:** Indian Air Quality Index (AQI) Dataset.
- **Volume:** ~842,160 hourly observations.
- **Variables:** 17 numeric features including pollutants (PM2.5, PM10, CO, NO2, SO2, O3), meteorological factors (Humidity, Pressure, Wind Speed), and location data.
- **Pre-processing:** Data was cleaned using KNN imputation to ensure high integrity for statistical modeling.

## 3. Analysis Workflow
* **Sampling:** Due to the large dataset size, a reproducible sample of 50,000 rows is used.
* **Suitability:** Validated via Kaiser-Meyer-Olkin (KMO: 0.70) and Bartlett’s Test of Sphericity.
* **PCA:** 5 Principal Components retained (71.5% variance explained) based on the Kaiser Criterion.
* **Clustering:** K-Means ($k=5$) applied to PC scores to map mathematical clusters to AQI bands.

## 4. Execution Instructions
To replicate this analysis, follow these steps:

1. **Environment Setup:** Ensure the dataset `aqi_india_38cols_knn_final.csv` is in your working directory.
2. **Library Installation:** Install the required R packages:
   ```r
   install.packages(c("tidyverse", "janitor", "corrplot", "psych", "FactoMineR", "factoextra"))
B. Configuration
Open R00277319_ANALYSIS.R and update the file path in Section 1:

R
# Update this line with your local directory path
df_raw <- read_csv("your_path/aqi_india_38cols_knn_final.csv")
C. Run the Analysis
Execute the script to automatically trigger the following workflow:

Data Sampling: A reproducible random sample of 50,000 rows is taken for computational efficiency.

Suitability Assessment: Runs KMO (Sampling Adequacy) and Bartlett’s Test (Sphericity).

PCA Execution: Generates 5 Principal Components explaining 71.5% of the variance.

Visualizations: Automatically generates:

Correlation Heatmaps: Showing pollutant inter-dependencies.

Scree Plots: Identifying the optimal number of components.

PCA Biplots: Mapping variables and individuals in reduced dimensions.

K-Means Elbow Plots: Visualizing cluster optimization.

Sensitivity Analysis Results: Comparing scaled vs. unscaled data.

4. Key Findings
Pollution Clustering: High pollution levels are strongly correlated across multiple species (PM, CO, NO2), suggesting common combustion sources like traffic and industry.

Independence: Weather factors such as wind and pressure (PC3) are largely independent of the core pollution load (PC1), meaning hazardous air quality can occur across various weather conditions.

AQI Alignment: The mathematical clustering model effectively distinguishes "Good" air quality zones from "Unhealthy" or "Hazardous" regions, showing high alignment with official health standards.

Methodological Validation: Sensitivity tests confirmed that Z-score standardization was mandatory; without it, high-variance variables like atmospheric pressure would have disproportionately biased the entire model.
