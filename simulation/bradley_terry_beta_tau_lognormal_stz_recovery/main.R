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
job_dir       <- file.path(project_root, "simulation", "bradley_terry_beta_tau_lognormal_stz_recovery")
code_dir      <- file.path(job_dir, "code")
artifacts_dir <- file.path(job_dir, "artifacts")
output_dir    <- file.path(job_dir, "output")
models_dir    <- file.path(project_root, "models")
dir.create(artifacts_dir, showWarnings = FALSE)
dir.create(output_dir, showWarnings = FALSE)

# Models
generative_model <- "bradley_terry_beta_tau_lognormal_stz"
fitted_model     <- "bradley_terry_beta_tau_lognormal_stz"


#### GENERATING TRUE PARAMETERS ####

# beta ~ Lognormal(mu = 1.5, sigma = 0.75)
# On the log scale: Normal(mean = 1.5, SD = 0.75)
# On the natural beta scale:
#   - Median: exp(1.5) = 4.48
#   - Mean:   exp(1.5 + 0.75^2 / 2) = exp(1.78125) = 5.94
#   - SD:     sqrt((exp(0.75^2) - 1) * exp(2*1.5 + 0.75^2)) = 5.16
#   - 95% interval (mu +/- 2*sigma): [exp(0), exp(3)] = [1.00, 20.09]
true_beta_location <- 1.5
true_beta_scale    <- 0.75

# tau ~ Normal(mean = 0, SD = 1)
# On the utility scale (where marginal SD of u = 1):
#   - Mean & Median: 0.0
#   - SD:            1.0
#   - 95% interval:  [-2.0, +2.0]
true_tau_location  <- 0.0
true_tau_scale     <- 1.0

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
n_warmup   <- 1000
n_sampling <- 2000

source(file.path(code_dir, "04_fit_model.R"))
source(file.path(code_dir, "05_extract_recovered_parameters.R"))


#### VISUALIZATION AND OUTPUT ####

source(file.path(code_dir, "06_plot_individual_recovery.R"))
source(file.path(code_dir, "07_plot_population_posteriors.R"))
source(file.path(code_dir, "08_plot_parameter_relationships.R"))
source(file.path(code_dir, "09_compile_recovery_pdf.R"))
