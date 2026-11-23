rm(list = ls())

#### SETUP ####

library(here)
library(brms)        # loaded before posterior so posterior's rhat()/ess_*() stay unmasked
library(tidyverse)
library(cmdstanr)
library(posterior)
library(bayesplot)
library(gridExtra)
library(patchwork)
library(ggdist)
library(cluster)

# Half-normal beta: beta ~ normal(beta_location, beta_scale) truncated at 0, with the
# priors beta_location ~ normal(4, 0.9), beta_scale ~ half-normal(0, 1.1).
# The prior itself is set in the .stan file.
analysis_name <- "beta_tau_halfnormal_stz"
model_name    <- "bradley_terry_beta_tau_halfnormal_stz"

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", analysis_name, "code")
artifacts_dir <- file.path(project_root, "analysis", analysis_name, "artifacts")
output_dir    <- file.path(project_root, "analysis", analysis_name, "output")
output_retest_dir    <- file.path(output_dir, "test-retest across sessions")
output_relations_dir <- file.path(output_dir, "relations between parameters")
output_clinical_dir  <- file.path(output_dir, "clinical reports")
data_path    <- file.path(project_root, "data", "processed")
model_path   <- file.path(project_root, "models", model_name, paste0(model_name, ".stan"))

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)
if (!dir.exists(output_retest_dir))    dir.create(output_retest_dir, recursive = TRUE)
if (!dir.exists(output_relations_dir)) dir.create(output_relations_dir, recursive = TRUE)
if (!dir.exists(output_clinical_dir))  dir.create(output_clinical_dir, recursive = TRUE)

# Sampling
n_chains   <- 4
n_warmup   <- 3000
n_sampling <- 5000

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "prep_data.R"))
source(file.path(code_dir, "fit_model.R"))
source(file.path(code_dir, "summarise_posterior.R"))
source(file.path(code_dir, "plot_hyperparameter_posteriors.R"))
source(file.path(code_dir, "join_phq9_and_write.R"))
source(file.path(code_dir, "plot_utility_test_retest.R"))
source(file.path(code_dir, "plot_scalar_param_test_retest.R"))
source(file.path(code_dir, "plot_p_higher_test_retest.R"))   # needs plot_param_test_retest() from the line above
source(file.path(code_dir, "plot_p_higher_above_tau_test_retest.R"))
source(file.path(code_dir, "plot_beta_test_retest_posterior.R"))
source(file.path(code_dir, "plot_beta_posterior_width.R"))   # needs beta_draws_by_wave.rds from the line above
source(file.path(code_dir, "plot_cross_parameter_scatter.R"))
source(file.path(code_dir, "prep_phq9_parameter_summary.R"))
source(file.path(code_dir, "plot_phq9_parameter_scatter.R"))
source(file.path(code_dir, "prep_utility_phq9_item_mapping.R"))
source(file.path(code_dir, "plot_utility_vs_phq9_item.R"))
source(file.path(code_dir, "prep_mean_utility_vs_phq9_item.R"))
source(file.path(code_dir, "plot_mean_utility_vs_phq9_item.R"))
source(file.path(code_dir, "plot_test_retest_summary.R"))
source(file.path(code_dir, "plot_parameter_relationships_summary.R"))

# ICC of tau and beta across days (Hypothesis 2, eq. [3]-[4]), from the two per-session fits.
# Standalone: needs only the SETUP block above.
source(file.path(code_dir, "fit_icc_tau_with_ms.R"))      # tau, with measurement error (posterior SD as se)
source(file.path(code_dir, "fit_icc_tau_without_ms.R"))   # tau, without measurement error (posterior medians)
source(file.path(code_dir, "fit_icc_beta_plain.R"))   # beta, without measurement error (posterior medians)
source(file.path(code_dir, "fit_icc_phq9_without_ms.R"))  # PHQ-9 sum score (observed, raw 0-27)
source(file.path(code_dir, "diagnose_icc.R"))         # all four ICC models
source(file.path(code_dir, "plot_icc_tau.R"))
source(file.path(code_dir, "plot_icc_beta.R"))
source(file.path(code_dir, "plot_icc_phq9.R"))

# ICC of item profiles (agreement, eq. [1]-[2]): CBCU utilities and PHQ-9 item ratings,
# both centred (not scaled) within participant x occasion, same 185 participants
source(file.path(code_dir, "fit_icc_utility_without_ms.R"))   # CBCU utilities
source(file.path(code_dir, "fit_icc_phq9_items.R"))           # PHQ-9 item ratings
source(file.path(code_dir, "diagnose_icc_items.R"))           # both models
source(file.path(code_dir, "plot_icc_items.R"))

# Five patients with different time 1 symptom profiles, one clinical report page each
source(file.path(code_dir, "select_profile_patients.R"))
source(file.path(code_dir, "select_high_severity_match.R"))   # adds a sixth, PHQ-9 >= 10 patient
# Two pairs (high and low PHQ-9 sum): same sum, highest vs lowest discriminability
source(file.path(code_dir, "select_discriminability_pairs.R"))   # needs p_higher_option.csv
source(file.path(code_dir, "prep_clinical_report.R"))
source(file.path(code_dir, "prep_clinical_report_summaries.R"))   # needs p_higher_option.csv
source(file.path(code_dir, "plot_clinical_report.R"))
source(file.path(code_dir, "plot_discriminability_pairs.R"))   # needs build_report_panels() from the line above
