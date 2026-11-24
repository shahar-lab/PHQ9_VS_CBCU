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
job_dir           <- file.path(project_root, "simulation", "bradley_terry_sigma_recovery")
code_dir          <- file.path(job_dir, "code")
artifacts_dir     <- file.path(job_dir, "artifacts")
output_dir        <- file.path(job_dir, "output")
output_retest_dir <- file.path(output_dir, "test-retest across sessions")
output_true_dir   <- file.path(output_dir, "true vs estimated")
models_dir        <- file.path(project_root, "models")
dir.create(artifacts_dir, showWarnings = FALSE)
dir.create(output_dir, showWarnings = FALSE)
dir.create(output_retest_dir, showWarnings = FALSE)
dir.create(output_true_dir, showWarnings = FALSE)

# Models
generative_model <- "bradley_terry_sigma"
fitted_model     <- "bradley_terry_sigma"


#### GENERATING TRUE PARAMETERS ####

# sigma (SD of each subject's utilities, on the logit scale) ~ Normal(6, 2) truncated at 0
# The truncation removes P(sigma < 0) = pnorm(-3) = 0.13%, so in practice:
#   - Mean & Median: ~6.0
#   - SD:            ~2.0
#   - 95% interval:  [2.1, 9.9]
# Close to the sigma implied by the beta-model fits of the real data (median 6.9,
# 5th-95th percentile 2.5-10.8), and includes low-consistency subjects (sigma ~2-3).
true_sigma_location <- 6
true_sigma_scale    <- 2

n_subjects <- 200   # number of agents
n_options  <- 15    # symptoms/items that can be offered (None is utility 16)

source(file.path(models_dir, generative_model, paste0(generative_model, ".R")))   # sim.block(), draw.u()
source(file.path(code_dir, "01_generate_true_parameters.R"))


#### GENERATING DATA ####

# The same true parameters generate both sessions (a perfectly stable trait), so
# test-retest differences come only from choice noise and estimation error.
n_trials   <- 105   # trials per agent per session
n_sessions <- 2

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

# True vs estimated (posterior median) per subject: sigma, tau, u
source(file.path(code_dir, "06_plot_true_vs_estimated.R"))

source(file.path(code_dir, "07_plot_parameter_test_retest.R"))
source(file.path(code_dir, "08_plot_choice_prediction_test_retest.R"))

# Hyperparameter recovery: posterior per session vs population value and sampled value
source(file.path(code_dir, "09_plot_hyperparameter_recovery.R"))

# All recovery figures in one PDF: output/recovery_summary.pdf
source(file.path(code_dir, "11_compile_recovery_pdf.R"))


#### MCMC DIAGNOSTICS ####

# output/mcmc_diagnostics.pdf, one block of pages per session
source(file.path(code_dir, "10_mcmc_diagnostics.R"))
