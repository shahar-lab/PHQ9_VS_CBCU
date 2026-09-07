rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(brms)
library(ggdist)
library(cmdstanr)
library(posterior)

# MASS is loaded via MASS::mvrnorm() calls rather than library(MASS) to avoid
# masking dplyr::select().

# here::here() anchors to the .Rproj root regardless of the working directory,
# so paths resolve identically on any machine without setwd() gymnastics.
project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "reliability_difference_sample_size", "code")
artifacts_dir <- file.path(project_root, "simulation", "reliability_difference_sample_size", "artifacts")
output_dir    <- file.path(project_root, "simulation", "reliability_difference_sample_size", "output")

# No data_path: this is a simulation study with no external data source.
# All (time1, time2) pairs are generated in-memory by the simulation code itself.

sample_sizes    <- c(50, 100, 200, 500, 1000)
n_iterations    <- 10
likert_r_mean   <- 0.6
cbcu_r_mean     <- 0.85
r_sd            <- 0.2

#### EXECUTE PIPELINE ####

# 1. Define the per-subject data generator used by the sweep
source(file.path(code_dir, "simulate_subjects.R"))

# 2. Define the fit+extract function used by the sweep
source(file.path(code_dir, "fit_and_extract.R"))

# 3. Sweep: simulate + fit across sample sizes x iterations (saves to artifacts/)
source(file.path(code_dir, "run_sweep.R"))

# 4. Plot HDI width vs. sample size (saves to output/)
source(file.path(code_dir, "plot_ci_width_by_n.R"))
