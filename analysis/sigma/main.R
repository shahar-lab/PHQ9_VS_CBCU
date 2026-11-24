rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(bayesplot)
library(gridExtra)
library(patchwork)
library(ggdist)

# No beta: logit(A) = u[A], logit(B) = u[B], logit(None) = u[None] = tau.
# sigma = subject-level SD of the 16 utilities (items + None) carries choice consistency;
# sigma ~ normal(sigma_location, sigma_scale) truncated at 0, with
# sigma_location ~ normal(5, 3), sigma_scale ~ half-normal(0, 3).
# The prior itself is set in the .stan file.
analysis_name <- "sigma"
model_name    <- "bradley_terry_sigma"

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", analysis_name, "code")
artifacts_dir <- file.path(project_root, "analysis", analysis_name, "artifacts")
output_dir    <- file.path(project_root, "analysis", analysis_name, "output")
output_retest_dir      <- file.path(output_dir, "test-retest across sessions")
output_retest_corr_dir <- file.path(output_retest_dir, "correlation")   # time 1 vs time 2 scatters
output_diagnostics_dir <- file.path(output_dir, "diagnostics")
output_clinical_dir    <- file.path(output_dir, "clinical reports")
data_path    <- file.path(project_root, "data", "processed")
model_path   <- file.path(project_root, "models", model_name, paste0(model_name, ".stan"))

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)
if (!dir.exists(output_retest_corr_dir)) dir.create(output_retest_corr_dir, recursive = TRUE)
if (!dir.exists(output_diagnostics_dir)) dir.create(output_diagnostics_dir, recursive = TRUE)
if (!dir.exists(output_clinical_dir))    dir.create(output_clinical_dir, recursive = TRUE)

# Sampling (same as beta_tau_halfnormal_stz)
n_chains   <- 4
n_warmup   <- 3000
n_sampling <- 5000

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "prep_data.R"))                       # one Stan data list per wave
source(file.path(code_dir, "fit_model.R"))                       # one fit per wave + diagnostics PDF
source(file.path(code_dir, "summarise_posterior.R"))             # posterior medians; sigma draws
source(file.path(code_dir, "plot_hyperparameter_posteriors.R"))  # sigma_location, sigma_scale
source(file.path(code_dir, "join_phq9_and_write.R"))             # artifacts/participant_parameters.csv
source(file.path(code_dir, "plot_test_retest.R"))                # sigma (HDI), tau, u, PHQ-9 sum
source(file.path(code_dir, "compare_with_beta_model.R"))         # vs analysis/beta_tau_halfnormal_stz

# Clinical reports (time 1): same patients and pairs as the beta report.
# Ladder = P(bothers most): softmax over the symptoms above tau plus None, per draw.
source(file.path(code_dir, "prep_clinical_report.R"))
source(file.path(code_dir, "prep_clinical_report_summaries.R"))  # sigma gauge axis, threshold counts
source(file.path(code_dir, "plot_clinical_report.R"))            # one page per patient
source(file.path(code_dir, "plot_discriminability_pairs.R"))     # needs build_report_parts() from above
