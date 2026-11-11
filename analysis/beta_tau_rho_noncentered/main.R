rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(bayesplot)
library(gridExtra)
library(broom)
library(knitr)
library(ggdist)
library(patchwork)

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", "beta_tau_rho_noncentered", "code")
artifacts_dir <- file.path(project_root, "analysis", "beta_tau_rho_noncentered", "artifacts")
output_dir    <- file.path(project_root, "analysis", "beta_tau_rho_noncentered", "output")
output_retest_dir    <- file.path(output_dir, "test-retest across sessions")
output_relations_dir <- file.path(output_dir, "relations between parameters")
output_repeat_dir    <- file.path(output_dir, "repeat types vs rho")
data_path    <- file.path(project_root, "data", "processed")
model_path    <- file.path(project_root, "models", "bradley_terry_beta_tau_rho_noncentered", "bradley_terry_beta_tau_rho_noncentered.stan")

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)
if (!dir.exists(output_retest_dir))    dir.create(output_retest_dir, recursive = TRUE)
if (!dir.exists(output_relations_dir)) dir.create(output_relations_dir, recursive = TRUE)
if (!dir.exists(output_repeat_dir))    dir.create(output_repeat_dir, recursive = TRUE)

# Sampling
n_chains   <- 4
n_warmup   <- 2000
n_sampling <- 2000

# Participants who chose skip on at least this proportion of a session's trials
# are flagged in plot_tau_vs_rho_skip_flag.R
skip_flag_threshold <- 0.85

# Participants with fewer neither (skip) choices than this in a session have unstable
# neither-repeat rates; the repeat-type analysis reports results with and without them
min_neither_trials <- 10

# A repeater pressed the same response (A/B, or neither) as on the previous trial on at
# least this proportion of consecutive pairs (plot_rho_by_repeat_type.R)
repeater_threshold <- 0.60

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "prep_data.R"))
source(file.path(code_dir, "fit_model.R"))
source(file.path(code_dir, "summarise_posterior.R"))
source(file.path(code_dir, "join_phq9_and_write.R"))
source(file.path(code_dir, "plot_utility_test_retest.R"))
source(file.path(code_dir, "plot_scalar_param_test_retest.R"))
source(file.path(code_dir, "prep_key_repeat.R"))
source(file.path(code_dir, "plot_cross_parameter_scatter.R"))
source(file.path(code_dir, "plot_tau_vs_rho_skip_flag.R"))
source(file.path(code_dir, "prep_repeat_types.R"))
source(file.path(code_dir, "summarise_repeat_types_vs_rho.R"))
source(file.path(code_dir, "check_average_rho.R"))
source(file.path(code_dir, "write_repeat_types_report.R"))
source(file.path(code_dir, "plot_rho_by_repeat_type.R"))
source(file.path(code_dir, "prep_phq9_parameter_summary.R"))
source(file.path(code_dir, "plot_phq9_parameter_scatter.R"))
source(file.path(code_dir, "prep_utility_phq9_item_mapping.R"))
source(file.path(code_dir, "plot_utility_vs_phq9_item.R"))
source(file.path(code_dir, "prep_mean_utility_vs_phq9_item.R"))
source(file.path(code_dir, "plot_mean_utility_vs_phq9_item.R"))
source(file.path(code_dir, "plot_test_retest_summary.R"))
source(file.path(code_dir, "plot_parameter_relationships_summary.R"))
