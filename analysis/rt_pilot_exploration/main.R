rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)

# here::here() anchors to the .Rproj root regardless of the working directory,
# so paths resolve identically on any machine without setwd() gymnastics.
project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", "rt_pilot_exploration", "code")
artifacts_dir <- file.path(project_root, "analysis", "rt_pilot_exploration", "artifacts")
output_dir    <- file.path(project_root, "analysis", "rt_pilot_exploration", "output")

dir.create(artifacts_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# One-off look at the user's own pilot session, read directly from data/collected/
# (not data/processed/) since this pilot run never goes through the real pipeline.
data_path <- file.path(project_root, "data", "collected", "results_lihi.csv")



#### EXECUTE PIPELINE ####

# 1. Clean pairwise trials (saves to artifacts/, leaves df in scope)
source(file.path(code_dir, "clean_pairwise_trials.R"))

# 2. Plot RT distribution (reuses in-memory df, saves to output/)
source(file.path(code_dir, "plot_rt_distribution.R"))

# 3. Plot RT by trial presentation order (reuses in-memory df, saves to output/)
source(file.path(code_dir, "plot_rt_by_trial.R"))
