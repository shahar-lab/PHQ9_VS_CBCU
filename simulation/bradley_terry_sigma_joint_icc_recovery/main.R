rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(ggplot2)
library(ggdist)
library(patchwork)
library(officer)
library(flextable)

# Directories
project_root  <- here::here()
job_dir       <- file.path(project_root, "simulation", "bradley_terry_sigma_joint_icc_recovery")
code_dir      <- file.path(job_dir, "code")
artifacts_dir <- file.path(job_dir, "artifacts")
output_dir    <- file.path(job_dir, "output")
models_dir    <- file.path(project_root, "models")
dir.create(artifacts_dir, showWarnings = FALSE)
dir.create(output_dir, showWarnings = FALSE)

# Models
generative_model <- "bradley_terry_sigma_joint_icc"
fitted_model     <- "bradley_terry_sigma_joint_icc"

source(file.path(models_dir, generative_model, paste0(generative_model, ".R")))
# compose_log_sigma(), compose_utilities(), generate_bradley_terry_sigma_joint_icc()


#### GENERATING TRUE PARAMETERS ####

# Three runs with different true consistency ICCs, crossed so the three ICCs are not tied to
# each other. Everything else is drawn fresh in each run. Files go to artifacts/<run_name>/.
true_icc_sigma_runs   <- c(0.5, 0.7, 0.9)   # sigma
true_icc_profile_runs <- c(0.8, 0.6, 0.4)   # the 15 items (shared; Hypothesis 1)
true_icc_tau_runs     <- c(0.7, 0.9, 0.5)   # None
run_names             <- sprintf("icc_sigma_%.1f", true_icc_sigma_runs)
run_labels            <- setNames(sprintf("Run %d: true ICC sigma %.1f, items %.1f, tau %.1f", seq_along(run_names),
                                          true_icc_sigma_runs, true_icc_profile_runs, true_icc_tau_runs), run_names)

# log(sigma), matched to the real data (analysis/sigma): mean over sessions 1.65
# (median sigma ~5.2 on this model's scale, ~0.7x the bradley_terry_sigma scale),
# SD within session 0.45, session 2 - session 1 shift 0.2 (sigma ~22% higher in session 2).
true_mu_log_sigma    <- 1.65
true_s_log_sigma     <- 0.45
true_delta_log_sigma <- 0.20

# Utilities (15 items + None):
true_m_sd       <- 0.7    # item means m_k ~ Normal(0, 0.7), shifted so all 16 means sum to zero
true_m_none     <- -0.25  # None mean, fixed: gives ~27% None choices, as in the real data (27.5%)
true_delta_u_sd <- 0.3    # session shifts delta_k ~ Normal(0, 0.3), centred

n_subjects <- 185   # number of agents (the real sample)
n_sessions <- 2
n_options  <- 15    # items; None is utility 16

source(file.path(code_dir, "01_generate_true_parameters.R"))
source(file.path(code_dir, "02_plot_true_parameters.R"))


#### GENERATING DATA ####

# Every unit (participant x session) sees all 105 pairs once, in random order and sides
n_trials <- choose(n_options, 2)   # 105 per session

source(file.path(code_dir, "03_generate_data.R"))


#### RECOVERING PARAMETERS ####

# One joint fit (both sessions) per run. Several hours each.
n_chains   <- 4
n_warmup   <- 3000
n_sampling <- 2000

source(file.path(code_dir, "04_fit_model.R"))
source(file.path(code_dir, "05_extract_recovered_parameters.R"))


#### VISUALIZATION AND OUTPUT ####

source(file.path(code_dir, "06_report_convergence.R"))          # R-hat, ESS, divergences per run
source(file.path(code_dir, "07_plot_population_location.R"))    # Figure 1
source(file.path(code_dir, "08_plot_icc_posteriors.R"))         # Figure 2 (ICC posteriors: sigma, profile, tau)
source(file.path(code_dir, "09_plot_icc_recovery.R"))           # Figure 3 (ICCs: true vs recovered, all runs)
source(file.path(code_dir, "10_plot_individual_recovery.R"))    # Figure 4 (sigma, tau, u per unit)
source(file.path(code_dir, "11_compile_recovery_pdf.R"))
source(file.path(code_dir, "12_write_recovery_docx.R"))
