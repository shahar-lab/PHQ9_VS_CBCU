rm(list = ls())

#### SETUP ####
# PSIS-LOO comparison of the two non-centered models (see summary.md, section 5):
#   beta_tau      (analysis/beta_tau_noncentered,     no perseveration)
#   beta_tau_rho  (analysis/beta_tau_rho_noncentered, one-trial perseveration rho)
# The earlier three-model comparison of the pairwise models (sections 1-4 of summary.md) is kept
# in output/ and artifacts/ (top level); this run writes to the subfolders named below.

library(here)
library(tidyverse)
library(posterior)
library(loo)
library(patchwork)

project_root   <- here::here()
code_dir       <- file.path(project_root, "analysis", "loo_comparison_three_models", "code")
comparison_id  <- "noncentered_beta_tau_vs_beta_tau_rho"
artifacts_dir  <- file.path(project_root, "analysis", "loo_comparison_three_models", "artifacts", comparison_id)
output_dir     <- file.path(project_root, "analysis", "loo_comparison_three_models", "output", comparison_id)
data_path      <- file.path(project_root, "data", "processed")

# Fits come from the two model jobs (their main.R must have been run first).
# Both .stan files compute trial-level log_lik in transformed parameters.
models <- list(
  beta_tau     = list(dir = file.path(project_root, "analysis", "beta_tau_noncentered", "artifacts"),     prefix = "fit_"),
  beta_tau_rho = list(dir = file.path(project_root, "analysis", "beta_tau_rho_noncentered", "artifacts"), prefix = "fit_")
)

# A trial is unreliable for PSIS-LOO above this Pareto k; a participant-session is flagged when
# more than flag_share of its trials exceed it
k_threshold <- 0.7
flag_share  <- 0.10

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "prep_log_lik.R"))
source(file.path(code_dir, "compute_loo.R"))
source(file.path(code_dir, "plot_pareto_k.R"))
source(file.path(code_dir, "compare_by_participant.R"))
