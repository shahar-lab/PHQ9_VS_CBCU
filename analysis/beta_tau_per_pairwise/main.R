rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(bayesplot)
library(gridExtra)

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", "beta_tau_per_pairwise", "code")
artifacts_dir <- file.path(project_root, "analysis", "beta_tau_per_pairwise", "artifacts")
output_dir    <- file.path(project_root, "analysis", "beta_tau_per_pairwise", "output")
data_path     <- file.path(project_root, "data", "processed")
model_path    <- file.path(project_root, "models", "bradley_terry_beta_tau_per", "bradley_terry_beta_tau_per.stan")

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "prep_data.R"))
source(file.path(code_dir, "fit_model.R"))
source(file.path(code_dir, "summarise_posterior.R"))
source(file.path(code_dir, "join_phq9_and_write.R"))
source(file.path(code_dir, "plot_utility_test_retest.R"))
source(file.path(code_dir, "plot_scalar_param_test_retest.R"))
source(file.path(code_dir, "plot_cross_parameter_scatter.R"))
