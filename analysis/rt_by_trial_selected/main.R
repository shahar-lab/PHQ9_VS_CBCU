rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", "rt_by_trial_selected", "code")
artifacts_dir <- file.path(project_root, "analysis", "rt_by_trial_selected", "artifacts")
output_dir    <- file.path(project_root, "analysis", "rt_by_trial_selected", "output")
data_path     <- file.path(project_root, "data", "processed")

# Participants to plot.
selected_ids <- c("67e0870d582edce0a2764d1f", "69f061c18bcd97022e700b95")

#### EXECUTE PIPELINE ####

# 1. Read processed CBCU trials of the selected participants.
source(file.path(code_dir, "01_prep_data.R"))

# 2. RT by trial, one panel per participant, time1 and time2 as two lines -> output/.
source(file.path(code_dir, "02_plot_rt_by_trial.R"))
