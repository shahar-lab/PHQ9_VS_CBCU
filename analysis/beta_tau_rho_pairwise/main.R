rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(bayesplot)
library(gridExtra)
library(ggdist)
library(patchwork)

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", "beta_tau_rho_pairwise", "code")
artifacts_dir <- file.path(project_root, "analysis", "beta_tau_rho_pairwise", "artifacts")
output_dir    <- file.path(project_root, "analysis", "beta_tau_rho_pairwise", "output")
output_posterior_dir <- file.path(output_dir, "posterior distributions")
output_relations_dir <- file.path(output_dir, "relations between parameters")
output_retest_dir    <- file.path(output_dir, "test-retest across sessions")
data_path   <- file.path(project_root, "data", "processed")
model_path    <- file.path(project_root, "models", "bradley_terry_beta_tau_rho_halfnormal", "bradley_terry_beta_tau_rho_halfnormal.stan")

if (!dir.exists(artifacts_dir))        dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))           dir.create(output_dir, recursive = TRUE)
if (!dir.exists(output_posterior_dir)) dir.create(output_posterior_dir, recursive = TRUE)
if (!dir.exists(output_relations_dir)) dir.create(output_relations_dir, recursive = TRUE)
if (!dir.exists(output_retest_dir))    dir.create(output_retest_dir, recursive = TRUE)

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "prep_data.R"))
source(file.path(code_dir, "fit_model.R"))
source(file.path(code_dir, "summarise_posterior.R"))
source(file.path(code_dir, "join_phq9_and_write.R"))
source(file.path(code_dir, "plot_posterior_hyperparameters.R"))
source(file.path(code_dir, "plot_posterior_subject_parameters.R"))
source(file.path(code_dir, "plot_cross_parameter_scatter.R"))
source(file.path(code_dir, "plot_scalar_param_test_retest.R"))
source(file.path(code_dir, "prep_phq9_parameter_summary.R"))
source(file.path(code_dir, "plot_phq9_parameter_scatter.R"))
