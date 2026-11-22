rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(bayesplot)
library(gridExtra)
library(patchwork)

# Same model and priors as analysis/beta_tau_halfnormal_stz, fitted ONCE to both sessions
# with session ignored: one beta, one tau and one set of utilities per subject, estimated
# from all of the subject's trials (both sessions). The priors are set in the .stan file:
#   beta_location ~ normal(4, 0.9), beta_scale ~ half-normal(0, 1),
#   tau_location ~ normal(0, 0.4), tau_scale ~ normal(1, 0.3) truncated at 0.
analysis_name <- "beta_tau_halfnormal_stz_joint"
model_name    <- "bradley_terry_beta_tau_halfnormal_stz"

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", analysis_name, "code")
artifacts_dir <- file.path(project_root, "analysis", analysis_name, "artifacts")
output_dir    <- file.path(project_root, "analysis", analysis_name, "output")
output_relations_dir <- file.path(output_dir, "relations between parameters")
data_path    <- file.path(project_root, "data", "processed")
model_path   <- file.path(project_root, "models", model_name, paste0(model_name, ".stan"))

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)
if (!dir.exists(output_relations_dir)) dir.create(output_relations_dir, recursive = TRUE)

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
source(file.path(code_dir, "plot_cross_parameter_scatter.R"))
source(file.path(code_dir, "prep_phq9_parameter_summary.R"))
source(file.path(code_dir, "plot_phq9_parameter_scatter.R"))
source(file.path(code_dir, "prep_utility_phq9_item_mapping.R"))
source(file.path(code_dir, "plot_utility_vs_phq9_item.R"))
source(file.path(code_dir, "prep_mean_utility_vs_phq9_item.R"))
source(file.path(code_dir, "plot_mean_utility_vs_phq9_item.R"))
source(file.path(code_dir, "plot_parameter_relationships_summary.R"))
