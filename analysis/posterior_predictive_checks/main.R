rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(posterior)

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", "posterior_predictive_checks", "code")
artifacts_dir <- file.path(project_root, "analysis", "posterior_predictive_checks", "artifacts")
output_dir    <- file.path(project_root, "analysis", "posterior_predictive_checks", "output")
data_path     <- file.path(project_root, "data", "processed")

# Fits come from the three model jobs (their main.R must have been run first)
job_dirs <- list(
  base = file.path(project_root, "analysis", "beta_tau_pairwise", "artifacts"),
  rho  = file.path(project_root, "analysis", "beta_tau_rho_pairwise", "artifacts"),
  per  = file.path(project_root, "analysis", "beta_tau_per_pairwise", "artifacts")
)
flags_path <- file.path(project_root, "analysis", "loo_comparison_three_models", "output", "participant_pareto_k_flags.csv")

# Posterior draws used per model (thinned, random but seeded); set small (e.g. 10) for a quick test run
n_draws <- 100
seed    <- 2026

# Sessions with fewer testable triads than this are excluded from the transitivity check
min_triads <- 50

# A session counts as a heavy skipper above this many skips (out of 105 trials)
heavy_skip_trials <- 20

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)

set.seed(seed)

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "prep_inputs.R"))
source(file.path(code_dir, "extract_draws.R"))
source(file.path(code_dir, "simulate_ppc.R"))
source(file.path(code_dir, "compute_statistics.R"))
source(file.path(code_dir, "compare_ppc.R"))
source(file.path(code_dir, "plot_ppc.R"))
source(file.path(code_dir, "compare_choices.R"))
source(file.path(code_dir, "plot_choices.R"))
source(file.path(code_dir, "plot_choice_distributions.R"))
source(file.path(code_dir, "plot_symptom_choices.R"))
