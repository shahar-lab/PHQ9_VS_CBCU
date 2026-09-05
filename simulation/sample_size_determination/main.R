rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(brms)
library(ggdist)

# MASS is loaded via MASS::mvrnorm() calls rather than library(MASS) to avoid
# masking dplyr::select().

# here::here() anchors to the .Rproj root regardless of the working directory,
# so paths resolve identically on any machine without setwd() gymnastics.
project_root  <- here::here()
code_dir      <- file.path(project_root, "simulation", "sample_size_determination", "code")
artifacts_dir <- file.path(project_root, "simulation", "sample_size_determination", "artifacts")
output_dir    <- file.path(project_root, "simulation", "sample_size_determination", "output")

# No data_path: this is a simulation study with no external data source.
# All (y1, y2) pairs are generated in-memory by the simulation code itself.

sample_sizes <- c(50, 100, 200, 500, 1000)
n_iterations <- 10
true_r       <- 0.85

#### EXECUTE PIPELINE ####

# 1. Define the simulate+fit function used by the sweep
source(file.path(code_dir, "simulate_and_recover.R"))

# 2. Sweep: simulate + fit across sample sizes x iterations (saves to artifacts/)
source(file.path(code_dir, "run_sweep.R"))

# 3. Plot HDI width vs. sample size (saves to output/)
source(file.path(code_dir, "plot_ci_width_by_n.R"))
