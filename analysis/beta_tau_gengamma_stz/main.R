rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(bayesplot)
library(gridExtra)
library(patchwork)

# Generalized gamma beta: log(beta) = beta_mu + beta_sigma * z, z a standardized
# log-gamma with shape k = 1 / beta_Q^2 (beta_Q -> 0 = lognormal; larger = left tail).
# Priors: beta_mu ~ normal(1.4, 0.3), beta_sigma ~ half-normal(0, 0.4),
# beta_Q ~ normal(1, 0.6) on [0.2, 3]. Set in the .stan file; prior_predictive_beta.R
# repeats them and must be kept in sync.
analysis_name <- "beta_tau_gengamma_stz"
model_name    <- "bradley_terry_beta_tau_gengamma_stz"

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

# Prior predictive check first: cheap (no data, no Stan). Look at
# output/prior_predictive_beta.png before running the fit below.
source(file.path(code_dir, "prior_predictive_beta.R"))

source(file.path(code_dir, "prep_data.R"))
source(file.path(code_dir, "fit_model.R"))
source(file.path(code_dir, "summarise_posterior.R"))
source(file.path(code_dir, "plot_beta_population.R"))   # needs prior_predictive_beta.R (helpers)
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
