rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(cmdstanr)
library(posterior)

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", "beta_tau_per_trial_predictions", "code")
artifacts_dir <- file.path(project_root, "analysis", "beta_tau_per_trial_predictions", "artifacts")
output_dir    <- file.path(project_root, "analysis", "beta_tau_per_trial_predictions", "output")
data_path     <- file.path(project_root, "data", "processed")
fits_dir      <- file.path(project_root, "analysis", "beta_tau_per_pairwise", "artifacts")

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)

waves <- c("time1", "time2")

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "01_extract_posterior_means.R"))
source(file.path(code_dir, "02_build_trial_table.R"))
