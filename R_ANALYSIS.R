# =============================================================================
# Multivariate Modelling Assignment
# Title:  Dimensionality Reduction of Indian Air Quality Data using PCA
# Author: Rishikesh Dharane 
# Dataset: aqi_india_38cols_knn_final.csv
# Method: Principal Component Analysis (PCA) + K-Means Clustering (Extension)
# =============================================================================


# =============================================================================
# SECTION 0 — LIBRARIES
# =============================================================================

# install.packages(c("tidyverse", "janitor", "corrplot", "psych", "FactoMineR", "factoextra"))

library(tidyverse)   # data wrangling
library(janitor)     # clean column names
library(corrplot)    # correlation heatmap
library(psych)       # KMO and Bartlett's test
library(FactoMineR)  # PCA
library(factoextra)  # PCA plots


# =============================================================================
# SECTION 1 — LOAD DATA
# =============================================================================

# Read the dataset — read_csv is faster than base read.csv
df_raw <- read_csv("C:/MTU Risshi/MSc Semester 2/MM/assignment1/aqi_india_38cols_knn_final.csv", show_col_types = FALSE)

df <- df_raw %>% clean_names()

# The full dataset has ~840,000 rows which exceeds available RAM for PCA.
# We take a reproducible random sample of 50,000 rows.
# This is large enough to produce statistically reliable PCA results.
set.seed(42)
df <- df %>% slice_sample(n = 50000)

cat("Working dataset size:", nrow(df), "rows\n")
# Clean column names: removes spaces and special characters
df <- df_raw %>% clean_names()

cat("Rows:", nrow(df), "| Columns:", ncol(df), "\n")
glimpse(df)


# =============================================================================
# SECTION 2 — DATA PREPARATION
# =============================================================================

# Select only continuous numeric variables for PCA.
# We drop: city, state, datetime, day_name, season, aqi_category (categorical)
# and is_weekend, is_raining, heavy_rain (binary 0/1 flags).
# This leaves 17 continuous variables — above the required minimum of 15.

continuous_vars <- c(
  "latitude", "longitude",
  "humidity_percent", "dew_point_c", "wind_gusts_kmh",
  "precipitation_mm", "pressure_msl_hpa", "cloud_cover_percent",
  "pm2_5_ugm3", "pm10_ugm3", "co_ugm3", "no2_ugm3",
  "so2_ugm3", "o3_ugm3", "dust_ugm3", "aod", "us_aqi"
)

df_numeric <- df %>% select(all_of(continuous_vars))

cat("Variables selected for PCA:", ncol(df_numeric), "\n")

# --- Check for missing values ------------------------------------------------
# The filename says KNN imputation was already applied, so we expect zero NAs.
# We confirm this before proceeding.

na_counts <- colSums(is.na(df_numeric))
cat("\nMissing values per variable:\n")
print(na_counts)

# If any NAs are found, fill them with the column median as a safety net
if (any(na_counts > 0)) {
  df_numeric <- df_numeric %>%
    mutate(across(everything(), ~ ifelse(is.na(.), median(., na.rm = TRUE), .)))
  cat("Median imputation applied.\n")
} else {
  cat("No missing values — data is clean.\n")
}

# --- Descriptive statistics --------------------------------------------------
cat("\nDescriptive statistics:\n")
summary(df_numeric)

# --- Why we must standardise -------------------------------------------------
# Variables have very different units and scales (e.g. pressure ~1000 hPa vs
# aod ~0.1).  Without standardisation, high-variance variables would dominate
# the PCA unfairly.  We use scale.unit = TRUE (z-score) to fix this.

cat("\nStandard deviations — shows why standardisation is needed:\n")
print(round(apply(df_numeric, 2, sd), 3))


# =============================================================================
# SECTION 3 — SUITABILITY CHECKS FOR PCA
# =============================================================================

# Compute the correlation matrix
cor_matrix <- cor(df_numeric)

# --- Figure 1: Correlation Heatmap -------------------------------------------
# We look for clusters of correlated variables.
# If everything is uncorrelated, PCA has nothing to compress.
# Expected: PM2.5, PM10, CO, NO2, SO2 form one cluster (pollution)
#           humidity, dew_point, cloud_cover form another (moisture)

corrplot(
  cor_matrix,
  method  = "color",   # colour squares by correlation strength
  type    = "upper",   # show only upper triangle (avoids duplication)
  order   = "hclust",  # group correlated variables together
  tl.col  = "black",
  tl.srt  = 45,
  tl.cex  = 0.7,
  title   = "Figure 1: Correlation Heatmap",
  mar     = c(0, 0, 2, 0)
)

# --- Bartlett's Test ---------------------------------------------------------
# Tests if the correlation matrix is significantly different from an identity
# matrix (no correlations).  We need p < 0.05 to justify PCA.

cat("\nBartlett's Test of Sphericity:\n")
bartlett_result <- cortest.bartlett(cor_matrix, n = nrow(df_numeric))
print(bartlett_result)
cat("p < 0.05 means variables are correlated => PCA is appropriate.\n")

# --- KMO Test ----------------------------------------------------------------
# Measures how suited the data is for PCA based on partial correlations.
# Rule: > 0.6 is acceptable, > 0.8 is good, > 0.9 is excellent.

cat("\nKMO Measure of Sampling Adequacy:\n")
kmo_result <- KMO(cor_matrix)
print(kmo_result)


# =============================================================================
# SECTION 4 — RUN PCA
# =============================================================================

# scale.unit = TRUE: standardise all variables to mean=0, SD=1 before PCA
# graph = FALSE: we will create our own plots below

res.pca <- PCA(df_numeric, scale.unit = TRUE, graph = FALSE)

# Get eigenvalues as a proper data frame (important — avoids $ operator errors)
eigenvalues <- as.data.frame(get_eigenvalue(res.pca))

cat("\nEigenvalues and variance explained:\n")
print(round(eigenvalues, 3))

# --- How many components to keep? --------------------------------------------
# Rule 1 — Kaiser criterion: keep components with eigenvalue > 1
#   (each such component explains more than one original variable)
# Rule 2 — keep enough components to reach 70% cumulative variance

n_kaiser <- sum(eigenvalues$eigenvalue > 1)
n_70pct  <- min(which(eigenvalues$cumulative.variance.percent >= 70))

cat("\nKaiser criterion (eigenvalue > 1): keep", n_kaiser, "components\n")
cat("70% variance threshold: reached at PC", n_70pct, "\n")
cat("We retain", n_kaiser, "components based on the Kaiser criterion.\n")

# --- Figure 2: Scree Plot ----------------------------------------------------
# The scree plot shows how much variance each PC explains.
# We look for the 'elbow' — the point where the curve flattens.
# Components before the elbow are worth keeping.

fviz_eig(
  res.pca,
  addlabels = TRUE,   # show % on each bar
  ylim      = c(0, 50)
) +
  labs(
    title = "Figure 2: Scree Plot — Variance Explained per Component",
    x     = "Principal Component",
    y     = "% Variance Explained"
  ) +
  theme_minimal()


# =============================================================================
# SECTION 5 — INTERPRET THE COMPONENTS
# =============================================================================

# Loadings tell us which original variables contribute most to each PC.
# A large positive loading means the variable increases with the PC score.
# A large negative loading means the variable decreases with the PC score.

loadings <- as.data.frame(res.pca$var$coord)
cat("\nVariable loadings on first", n_kaiser, "components:\n")
print(round(loadings[, 1:n_kaiser], 3))

# --- Figure 3: Loading Plot --------------------------------------------------
# Arrows pointing in the same direction = positively correlated variables.
# Arrow length = how strongly the variable contributes to that PC.
# This is one of the most important plots to explain to the professor.

fviz_pca_var(
  res.pca,
  col.var = "cos2",              # colour by quality of representation
  gradient.cols = c("grey", "steelblue", "darkred"),
  repel   = TRUE,                # stop labels overlapping
  title   = "Figure 3: Variable Loading Plot (PC1 vs PC2)"
) +
  theme_minimal()

# --- Figure 4: Score Plot (sampled for speed) --------------------------------
# Each point = one observation projected into PC space.
# We colour by AQI category to see if PCA separates pollution levels.
# NOTE: the dataset has ~840,000 rows — plotting all of them would crash
# RStudio.  We take a random sample of 5,000 rows for the plot only.
# The PCA itself was computed on the full dataset.

set.seed(42)
sample_idx  <- sample(nrow(df), 5000)   # 5,000 random row indices
scores_plot <- as.data.frame(res.pca$ind$coord)[sample_idx, ]
scores_plot$aqi_category <- df$aqi_category[sample_idx]

ggplot(scores_plot, aes(x = Dim.1, y = Dim.2, colour = aqi_category)) +
  geom_point(alpha = 0.4, size = 0.9) +
  labs(
    title    = "Figure 4: PCA Score Plot (sample of 5,000 observations)",
    subtitle = "Coloured by AQI category — PCA computed on full dataset",
    x        = paste0("PC1 (", round(eigenvalues[1, "variance.percent"], 1), "%)"),
    y        = paste0("PC2 (", round(eigenvalues[2, "variance.percent"], 1), "%)"),
    colour   = "AQI Category"
  ) +
  theme_minimal()


# =============================================================================
# SECTION 6 — EXTENSION: K-MEANS CLUSTERING
# =============================================================================
# The assignment requires comparison with a second multivariate method.
# We cluster the PCA scores to see if natural groups emerge without using
# the AQI labels — then compare to the real labels at the end.

# Use only the retained PC scores (not the original 17 variables)
pc_scores <- as.data.frame(res.pca$ind$coord[, 1:n_kaiser])

# --- Choose k using the Elbow method -----------------------------------------
# We run K-Means for k = 2 to 8 and plot total within-cluster SS.
# The 'elbow' point (where improvement slows down) suggests the best k.
# We use a 10% sample here to keep it fast.

# Use only the retained PC scores (not the original 17 variables)
pc_scores <- as.data.frame(res.pca$ind$coord[, 1:n_kaiser])

# For the elbow plot we use only 2,000 rows — it only needs an approximate
# answer and fviz_nbclust is very memory-heavy internally
set.seed(42)
sample_clust <- pc_scores[sample(nrow(pc_scores), size = 2000), ]

fviz_nbclust(
  sample_clust,
  kmeans,
  method  = "wss",
  k.max   = 8
) +
  labs(
    title = "Figure 5: Elbow Plot — Choosing Number of Clusters",
    x     = "Number of Clusters (k)",
    y     = "Total Within-Cluster Sum of Squares"
  ) +
  theme_minimal()

# --- Run K-Means with k = 5 --------------------------------------------------
# We choose k = 5 to match the 5 AQI pollution bands:
# Good / Moderate / Unhealthy for Sensitive Groups / Unhealthy / Very Unhealthy

set.seed(42)
km <- kmeans(pc_scores, centers = 5, nstart = 25, iter.max = 100)
# nstart = 25: tries 25 random starting positions and keeps the best result
# iter.max = 100: maximum iterations per run

cat(sprintf("\nK-Means (k=5): Between-SS / Total-SS = %.1f%%\n",
            100 * km$betweenss / km$totss))
# Higher % = clusters are well separated

# --- Figure 6: Cluster plot (sampled) ----------------------------------------
fviz_cluster(
  km,
  data         = pc_scores[sample_idx, ],   # same 5k sample used for score plot
  geom         = "point",
  ellipse.type = "norm",
  alpha        = 0.4,
  pointsize    = 0.8,
  title        = "Figure 6: K-Means Clusters in PCA Space (sample of 5,000)"
) +
  theme_minimal()

# --- Compare clusters to real AQI labels -------------------------------------
# A cross-table shows how well the unsupervised clusters match the true labels.
# If each cluster maps cleanly to one AQI category, PCA has captured the
# pollution structure well.

cat("\nCluster vs AQI Category cross-table:\n")
cross_tab <- table(Cluster = as.factor(km$cluster), AQI = df$aqi_category)
print(cross_tab)

cat("\nRow proportions (what % of each cluster belongs to each AQI band):\n")
print(round(prop.table(cross_tab, margin = 1), 2))


# =============================================================================
# SECTION 7 — SENSITIVITY ANALYSIS
# =============================================================================

# Test 1: Run PCA WITHOUT standardisation to prove scaling matters.
# If PC1 grabs almost all variance when unscaled, it confirms that
# high-variance variables (e.g. pressure, co_ugm3) were dominating.

res.pca.unscaled  <- PCA(df_numeric, scale.unit = FALSE, graph = FALSE)
eigen_unscaled    <- as.data.frame(get_eigenvalue(res.pca.unscaled))

cat("\n--- Sensitivity: Unscaled PCA (first 3 PCs) ---\n")
print(round(eigen_unscaled[1:3, ], 2))

cat("\n--- Sensitivity: Scaled PCA (first 3 PCs) ---\n")
print(round(eigenvalues[1:3, ], 2))

cat("\nIf unscaled PC1 variance >> scaled PC1 variance,\n")
cat("this confirms standardisation was necessary.\n")

# Test 2: Remove us_aqi (a composite index) and re-run PCA.
# This checks the results are not just driven by the AQI summary variable.

res.pca.no_aqi <- PCA(df_numeric %>% select(-us_aqi), scale.unit = TRUE, graph = FALSE)
eigen_no_aqi   <- as.data.frame(get_eigenvalue(res.pca.no_aqi))

cat("\n--- Sensitivity: PCA without us_aqi (first 5 PCs) ---\n")
print(round(eigen_no_aqi[1:5, ], 2))
cat("Similar pattern to full model = results are stable.\n")


# =============================================================================
# SECTION 8 — SESSION INFO
# =============================================================================
sessionInfo()

