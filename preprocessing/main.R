rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(jsonlite)

project_root  <- here::here()
code_dir      <- file.path(project_root, "preprocessing", "code")
output_dir    <- file.path(project_root, "preprocessing", "output")
collected_dir <- file.path(project_root, "data", "collected")   # data as it arrived — READ-ONLY
raw_dir       <- file.path(project_root, "data", "raw")

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
if (!dir.exists(raw_dir))    dir.create(raw_dir, recursive = TRUE)

# Renders empty report cells as blanks rather than "NA".
options(knitr.kable.NA = "")



#### EXECUTE PIPELINE ####

# Running this script alone rebuilds data/raw/ and preprocessing/output/ from
# data/collected/, reading data/collected/ as read-only.

# 1. Read collected data: row-bind every CSV in first_wave/ and second_wave/,
# reconcile the session-id column name, and tag each row with study_session.
source(file.path(code_dir, "read_collected.R"))

# 2. Build raw data: split the long-format collected log into the four tidy
# CSVs (cbcu_results, cbcu_quizz, phq9_results, feedback), apply type
# coercion, write them to data/raw/, and write collected-to-raw-report.md.
source(file.path(code_dir, "build_raw.R"))
