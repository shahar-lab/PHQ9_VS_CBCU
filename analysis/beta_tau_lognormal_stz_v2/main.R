rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(bayesplot)
library(gridExtra)
library(patchwork)

# Lognormal beta with the priors beta_location ~ normal(1.25, 0.25),
# beta_scale ~ half-normal(0, 0.35). The prior itself is set in the .stan file.
analysis_name <- "beta_tau_lognormal_stz_v2"
model_name    <- "bradley_terry_beta_tau_lognormal_stz_v2"

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", analysis_name, "code")
artifacts_dir <- file.path(project_root, "analysis", analysis_name, "artifacts")
output_dir    <- file.path(project_root, "analysis", analysis_name, "output")
output_retest_dir    <- file.path(output_dir, "test-retest across sessions")
output_relations_dir <- file.path(output_dir, "relations between parameters")
data_path    <- file.path(project_root, "data", "processed")
model_path   <- file.path(project_root, "models", model_name, paste0(model_name, ".stan"))

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)
if (!dir.exists(output_retest_dir))    dir.create(output_retest_dir, recursive = TRUE)
if (!dir.exists(output_relations_dir)) dir.create(output_relations_dir, recursive = TRUE)

# Sampling
n_chains   <- 4
n_warmup   <- 2000
n_sampling <- 4000

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "prep_data.R"))
source(file.path(code_dir, "fit_model.R"))
source(file.path(code_dir, "summarise_posterior.R"))
source(file.path(code_dir, "join_phq9_and_write.R"))
source(file.path(code_dir, "plot_utility_test_retest.R"))
source(file.path(code_dir, "plot_scalar_param_test_retest.R"))
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
