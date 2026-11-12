rm(list = ls())

#### SETUP ####
# Posterior predictive accuracy for the two non-centered models:
#   beta_tau      (analysis/beta_tau_noncentered,     no perseveration)
#   beta_tau_rho  (analysis/beta_tau_rho_noncentered, one-trial perseveration rho)
# For every participant: the share of trials on which the model's predicted response equals the
# observed response, its posterior predictive distribution, a histogram per model, and a
# comparison of the two models. See summary.md, section "Accuracy of the non-centered models".
# Independent of main.R (which checks the older pairwise models).

library(here)
library(tidyverse)
library(posterior)
library(patchwork)

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", "posterior_predictive_checks", "code")
artifacts_dir <- file.path(project_root, "analysis", "posterior_predictive_checks", "artifacts")
output_dir    <- file.path(project_root, "analysis", "posterior_predictive_checks", "output", "accuracy_noncentered")
data_path     <- file.path(project_root, "data", "processed")

# Fits come from the two model jobs (their main.R must have been run first)
job_dirs <- list(
  base = file.path(project_root, "analysis", "beta_tau_noncentered", "artifacts"),
  rho  = file.path(project_root, "analysis", "beta_tau_rho_noncentered", "artifacts")
)
model_labels <- c(base = "beta_tau", rho = "beta_tau_rho")
model_colors <- c(beta_tau = "#2a78d6", beta_tau_rho = "#eb6834")

# Posterior draws used per fit (random but seeded, same indices for both models)
n_draws <- 1000
seed    <- 2026

# The fits are 1.5-2.7 GB each; the thinned draws are cached so reruns skip loading them.
# Set to FALSE after refitting a model or changing n_draws.
reuse_cached_draws <- TRUE
draws_cache_path   <- file.path(artifacts_dir, "noncentered_draws.rds")

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)

set.seed(seed)

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "noncentered_prep_inputs.R"))
source(file.path(code_dir, "noncentered_extract_draws.R"))
source(file.path(code_dir, "noncentered_predict_accuracy.R"))
source(file.path(code_dir, "noncentered_plot_accuracy.R"))
source(file.path(code_dir, "noncentered_compare_accuracy.R"))
