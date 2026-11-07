rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(posterior)
library(loo)

project_root   <- here::here()
code_dir       <- file.path(project_root, "analysis", "loo_comparison_three_models", "code")
artifacts_dir  <- file.path(project_root, "analysis", "loo_comparison_three_models", "artifacts")
output_dir     <- file.path(project_root, "analysis", "loo_comparison_three_models", "output")

# Fits come from the three model jobs (run their main.R first, after the log_lik edit to the .stan files)
job_dirs <- list(
  base = file.path(project_root, "analysis", "beta_tau_pairwise", "artifacts"),
  rho  = file.path(project_root, "analysis", "beta_tau_rho_pairwise", "artifacts"),
  per  = file.path(project_root, "analysis", "beta_tau_per_pairwise", "artifacts")
)

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "prep_log_lik.R"))
source(file.path(code_dir, "compute_loo.R"))
source(file.path(code_dir, "plot_pareto_k.R"))
