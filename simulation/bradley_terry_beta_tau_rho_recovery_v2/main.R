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
code_dir      <- file.path(project_root, "simulation", "bradley_terry_beta_tau_rho_recovery_v2", "code")
artifacts_dir <- file.path(project_root, "simulation", "bradley_terry_beta_tau_rho_recovery_v2", "artifacts")
output_dir    <- file.path(project_root, "simulation", "bradley_terry_beta_tau_rho_recovery_v2", "output")
dir.create(artifacts_dir, showWarnings = FALSE)
dir.create(output_dir, showWarnings = FALSE)
model_r_path  <- file.path(project_root, "models", "bradley_terry_beta_tau_rho", "bradley_terry_beta_tau_rho.R")
model_path    <- file.path(project_root, "models", "bradley_terry_beta_tau_rho", "bradley_terry_beta_tau_rho.stan")

# Loads sim.block(), the mechanistic data-generating function for this model.
source(model_r_path)

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "simulated_data.R"))
source(file.path(code_dir, "fit_model.R"))
source(file.path(code_dir, "recover_compare.R"))
source(file.path(code_dir, "plot_u_recovery.R"))
source(file.path(code_dir, "plot_beta_recovery.R"))
source(file.path(code_dir, "plot_tau_recovery.R"))
source(file.path(code_dir, "plot_rho_recovery.R"))
source(file.path(code_dir, "prep_group_posterior.R"))
source(file.path(code_dir, "plot_group_recovery.R"))
source(file.path(code_dir, "plot_full_recovery_panel.R"))
