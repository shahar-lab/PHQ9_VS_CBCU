rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(ggplot2)
library(ggdist)
library(patchwork)

# Directories
project_root      <- here::here()
job_dir           <- file.path(project_root, "simulation", "bradley_terry_beta_tau_halfnormal_stz_recovery")
code_dir          <- file.path(job_dir, "code")
artifacts_dir     <- file.path(job_dir, "artifacts")
output_dir        <- file.path(job_dir, "output")
output_retest_dir <- file.path(output_dir, "test-retest across sessions")
models_dir        <- file.path(project_root, "models")
dir.create(artifacts_dir, showWarnings = FALSE)
dir.create(output_dir, showWarnings = FALSE)
dir.create(output_retest_dir, showWarnings = FALSE)

# Models
generative_model <- "bradley_terry_beta_tau_halfnormal_stz"
fitted_model     <- "bradley_terry_beta_tau_halfnormal_stz"


#### GENERATING TRUE PARAMETERS ####

# beta ~ Normal(location = 4, scale = 1) truncated at 0
# The truncation removes P(beta < 0) = pnorm(-4) = 3e-5, so in practice:
#   - Mean & Median: 4.0
#   - SD:            1.0
#   - 95% interval:  [2.0, 6.0]
true_beta_location <- 4
true_beta_scale    <- 1

# tau ~ Normal(mean = 0, SD = 1)
# On the utility scale (where marginal SD of u = 1):
#   - Mean & Median: 0.0
#   - SD:            1.0
#   - 95% interval:  [-2.0, +2.0]
true_tau_location  <- 0
true_tau_scale     <- 1

n_subjects <- 200   # number of agents
n_options  <- 15    # symptoms/items that can be offered

source(file.path(code_dir, "01_generate_true_parameters.R"))


#### GENERATING DATA ####

# The same true parameters generate both sessions (a perfectly stable trait), so
# test-retest differences come only from choice noise and estimation error.
n_trials   <- 105   # trials per agent per session
n_sessions <- 2

source(file.path(models_dir, generative_model, paste0(generative_model, ".R")))
source(file.path(code_dir, "02_generate_data.R"))


#### RECOVERING PARAMETERS ####

# One fit per session, as in the analysis of the real data
n_chains   <- 4
n_warmup   <- 3000
n_sampling <- 2000

source(file.path(code_dir, "03_fit_model.R"))
source(file.path(code_dir, "04_extract_subject_estimates.R"))
source(file.path(code_dir, "05_compute_choice_prediction.R"))


#### VISUALIZATION AND OUTPUT ####

source(file.path(code_dir, "06_plot_parameter_test_retest.R"))
source(file.path(code_dir, "07_plot_choice_prediction_test_retest.R"))

# Hyperparameter recovery: posterior per session vs population value and sampled value
source(file.path(code_dir, "08_plot_hyperparameter_recovery.R"))

# All recovery figures in one PDF: output/recovery_summary.pdf
source(file.path(code_dir, "10_compile_recovery_pdf.R"))


#### MCMC DIAGNOSTICS ####

# output/mcmc_diagnostics.pdf, one block of pages per session
source(file.path(code_dir, "09_mcmc_diagnostics.R"))
