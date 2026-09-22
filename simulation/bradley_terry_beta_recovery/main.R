rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)
library(ggplot2)
library(ggdist)

project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "bradley_terry_beta_recovery", "code")
artifacts_dir <- file.path(project_root, "simulation", "bradley_terry_beta_recovery", "artifacts")
output_dir    <- file.path(project_root, "simulation", "bradley_terry_beta_recovery", "output")
dir.create(artifacts_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
model_path    <- file.path(project_root, "models", "bradley_terry_beta", "bradley_terry_beta.stan")
model_r_path  <- file.path(project_root, "models", "bradley_terry_beta", "bradley_terry_beta.R")

source(model_r_path)

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "simulated_data.R"))
source(file.path(code_dir, "fit_model.R"))
source(file.path(code_dir, "recover_compare.R"))
source(file.path(code_dir, "plot_u_recovery.R"))
source(file.path(code_dir, "plot_beta_recovery.R"))
source(file.path(code_dir, "prep_group_posterior.R"))
source(file.path(code_dir, "plot_group_recovery.R"))
