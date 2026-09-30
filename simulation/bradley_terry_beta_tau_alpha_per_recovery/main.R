rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(ggplot2)
library(ggdist)
library(patchwork)

project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "bradley_terry_beta_tau_alpha_per_recovery", "code")
artifacts_dir <- file.path(project_root, "simulation", "bradley_terry_beta_tau_alpha_per_recovery", "artifacts")
output_dir    <- file.path(project_root, "simulation", "bradley_terry_beta_tau_alpha_per_recovery", "output")
models_dir    <- file.path(project_root, "models")
dir.create(artifacts_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

generative_model <- "bradley_terry_beta_tau_alpha_per"
fitted_model     <- "bradley_terry_beta_tau_alpha_per"

# Recovery criteria (approved in the Job Card)
r_min                 <- 0.75   # Pearson r between true and recovered (posterior mean)
bias_max_sd_fraction  <- 0.10   # |mean(recovered - true)| within 10% of the true SD
coverage_lo           <- 0.80   # 90% credible-interval coverage, lower bound
coverage_hi           <- 0.95   # 90% credible-interval coverage, upper bound


#### GENERATING TRUE PARAMETERS ####
# Population values are set here; beta = exp(log_beta), alpha_per = plogis(logit_alpha_per).
# alpha_per is drawn on the logit scale and passed to sim.block() on the probability scale.

mu_log_beta    <- 0.5
sigma_log_beta <- 0.3
mu_tau         <- 0
sigma_tau      <- 1
mu_rho         <- 0
sigma_rho      <- 0.75
mu_logit_alpha <- 0
sigma_alpha    <- 1

n_subjects <- 200
n_options  <- 15

source(file.path(code_dir, "01_generate_true_parameters.R"))
source(file.path(code_dir, "02_plot_true_parameters.R"))


#### GENERATING DATA ####

n_trials   <- 105
n_sessions <- 1   # the task has no sessions

source(file.path(models_dir, generative_model, paste0(generative_model, ".R")))
source(file.path(code_dir, "03_generate_data.R"))


#### RECOVERING PARAMETERS ####

model_path <- file.path(models_dir, fitted_model, paste0(fitted_model, ".stan"))

n_chains   <- 4
n_warmup   <- 3000
n_sampling <- 2000

source(file.path(code_dir, "04_fit_model.R"))
source(file.path(code_dir, "05_extract_recovered_parameters.R"))
source(file.path(code_dir, "06_recovery_metrics.R"))


#### VISUALIZATION AND OUTPUT ####

source(file.path(code_dir, "07_plot_u_recovery.R"))
source(file.path(code_dir, "08_plot_beta_recovery.R"))
source(file.path(code_dir, "09_plot_tau_recovery.R"))
source(file.path(code_dir, "10_plot_alpha_per_recovery.R"))
source(file.path(code_dir, "11_plot_rho_recovery.R"))
source(file.path(code_dir, "12_plot_full_recovery_panel.R"))
source(file.path(code_dir, "13_prep_group_posterior.R"))
source(file.path(code_dir, "14_plot_group_recovery.R"))
source(file.path(code_dir, "15_plot_mu_sigma_posteriors.R"))
source(file.path(code_dir, "16_compile_summary_pdf.R"))
