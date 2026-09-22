rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(patchwork)

# here::here() anchors to the .Rproj root regardless of the working directory,
# so paths resolve identically on any machine without setwd() gymnastics.
project_root <- here::here()
code_dir     <- file.path(project_root, "simulation", "icc_sample_size_panel", "code")
output_dir   <- file.path(project_root, "simulation", "icc_sample_size_panel", "output")

# ASSUMED[project-rules.md's canonical folder set includes artifacts/ for every
# analysis/simulation folder]: kept an (empty) artifacts_dir for structural
# consistency, even though this folder runs no new simulation and writes
# nothing into it -- plot_panel.R reads its 3 source .rds files directly from
# the two OTHER folders' own artifacts/ directories, not from this one.
artifacts_dir <- file.path(project_root, "simulation", "icc_sample_size_panel", "artifacts")

if (!dir.exists(artifacts_dir)) dir.create(artifacts_dir, recursive = TRUE)
if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)

#### EXECUTE PIPELINE ####

source(file.path(code_dir, "plot_panel.R"))

