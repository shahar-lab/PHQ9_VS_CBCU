rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(brms)
library(ggdist)
library(cmdstanr)
library(posterior)

# here::here() anchors to the .Rproj root regardless of the working directory,
# so paths resolve identically on any machine without setwd() gymnastics.
project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "reliability_sample_size_subject_item_crossed", "code")
artifacts_dir <- file.path(project_root, "simulation", "reliability_sample_size_subject_item_crossed", "artifacts")
output_dir    <- file.path(project_root, "simulation", "reliability_sample_size_subject_item_crossed", "output")

# No data_path: this is a simulation study with no external data source. Both
# outcomes' crossed subject x item data are generated in-memory by the
# simulation code itself, using fixed constants (see summary.md for full
# rationale/derivation of every value).

sample_sizes <- c(50, 100, 200, 500, 1000)

cbcu_grand_mean    <- 0
cbcu_sigma_subject <- 1
cbcu_sigma_item    <- 0.3
cbcu_sigma_e       <- 0.3
cbcu_n_items       <- 15

phq9_grand_mean    <- 1.5
phq9_sigma_subject <- 1.17
phq9_sigma_item    <- 0.4
phq9_sigma_e       <- 0.67
phq9_n_items       <- 9

dir.create(artifacts_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

#### EXECUTE PIPELINE ####

# 1. Define the crossed subject x item data generator used by both sweeps
source(file.path(code_dir, "simulate_subjects_items.R"))

# 2. Define the fit+extract function used by both sweeps
source(file.path(code_dir, "fit_and_extract.R"))

# 3. Sweep: simulate + fit across sample sizes, once per outcome (saves to artifacts/)
source(file.path(code_dir, "run_sweep.R"))

# 4. Plot HDI width vs. sample size, once per outcome (saves to output/)
source(file.path(code_dir, "plot_ci_width_by_n.R"))
