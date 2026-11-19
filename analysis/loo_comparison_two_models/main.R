rm(list = ls())

#### SETUP ####
# PSIS-LOO comparison of two population distributions for beta (see summary.md):
#   lognormal   (analysis/beta_tau_lognormal_stz_v2): beta lognormal,
#               beta_location ~ normal(1.25, 0.25), beta_scale ~ half-normal(0, 0.35)
#   halfnormal  (analysis/beta_tau_halfnormal_stz):   beta normal truncated at 0,
#               beta_location ~ normal(4, 0.9), beta_scale ~ half-normal(0, 1.1)
# Everything else in the two models is identical.

library(here)
library(tidyverse)
library(posterior)
library(loo)
library(patchwork)

analysis_name <- "loo_comparison_two_models"

project_root   <- here::here()
code_dir       <- file.path(project_root, "analysis", analysis_name, "code")
artifacts_dir  <- file.path(project_root, "analysis", analysis_name, "artifacts")
output_dir     <- file.path(project_root, "analysis", analysis_name, "output")
data_path      <- file.path(project_root, "data", "processed")

# Fits come from the two model jobs (their main.R must have been run first).
# Both .stan files compute trial-level log_lik in transformed parameters.
# The first model is the reference: differences are second minus first.
models <- list(
  lognormal  = list(dir = file.path(project_root, "analysis", "beta_tau_lognormal_stz_v2", "artifacts"), prefix = "fit_"),
  halfnormal = list(dir = file.path(project_root, "analysis", "beta_tau_halfnormal_stz", "artifacts"),   prefix = "fit_")
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
