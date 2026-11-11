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
project_root  <- here::here()
job_dir       <- file.path(project_root, "simulation", "parameter_recovery_noncentered_model")
code_dir      <- file.path(job_dir, "code")
artifacts_dir <- file.path(job_dir, "artifacts")
output_dir    <- file.path(job_dir, "output")
models_dir    <- file.path(project_root, "models")
dir.create(artifacts_dir, showWarnings = FALSE)
dir.create(output_dir, showWarnings = FALSE)

# Models
generative_model <- "bradley_terry_beta_tau_rho_noncentered"
fitted_model     <- "bradley_terry_beta_tau_rho_noncentered"


#### GENERATING TRUE PARAMETERS ####
# Population distributions the subject-level parameters are drawn from, matching
# the fitting model's population forms:
#   beta ~ normal(mu_beta, sigma_beta) truncated at 0
#   tau  ~ normal(mu_tau, sigma_tau)
#   rho  ~ normal(mu_rho, sigma_rho)
# No transform onto the unit interval is used. Utilities u are drawn per subject
# and standardized to mean 0 and SD 1, as in the Stan model.

mu_beta    <- 3
sigma_beta <- 1
mu_tau     <- 0
sigma_tau  <- 1
mu_rho     <- 0
sigma_rho  <- 1

n_subjects <- 200   # number of agents
n_options  <- 15    # symptoms/items that can be offered

source(file.path(code_dir, "01_generate_true_parameters.R"))
source(file.path(code_dir, "02_plot_true_parameters.R"))


#### GENERATING DATA ####

n_trials   <- 105   # trials per agent per session
n_sessions <- 1     # the task has no sessions

source(file.path(models_dir, generative_model, paste0(generative_model, ".R")))
source(file.path(code_dir, "03_generate_data.R"))


#### RECOVERING PARAMETERS ####

n_chains   <- 4
n_warmup   <- 2000
n_sampling <- 2000

source(file.path(code_dir, "04_fit_model.R"))
source(file.path(code_dir, "05_extract_recovered_parameters.R"))


#### VISUALIZATION AND OUTPUT ####

source(file.path(code_dir, "06_plot_individual_recovery.R"))
source(file.path(code_dir, "07_plot_population_posteriors.R"))
source(file.path(code_dir, "08_compile_recovery_pdf.R"))
