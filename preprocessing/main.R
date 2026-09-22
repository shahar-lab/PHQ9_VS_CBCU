rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(jsonlite)
library(hms)
library(knitr)

project_root            <- here::here()
preprocessing_dir       <- file.path(project_root, "preprocessing")

#preprocessing directories
code_dir                <- file.path(preprocessing_dir, "code")
artifacts_dir           <- file.path(preprocessing_dir, "artifacts")
dir.create(code_dir,         recursive = TRUE, showWarnings = FALSE)
dir.create(artifacts_dir,    recursive = TRUE, showWarnings = FALSE)

#output directories
output_dir              <- file.path(preprocessing_dir, "output")
output_collected_dir    <- file.path(output_dir, "collected")
output_raw_dir          <- file.path(output_dir, "raw")
output_processed_dir    <- file.path(output_dir, "processed")
dir.create(output_dir,            recursive = TRUE, showWarnings = FALSE)
dir.create(output_collected_dir,  recursive = TRUE, showWarnings = FALSE)
dir.create(output_raw_dir,        recursive = TRUE, showWarnings = FALSE)
dir.create(output_processed_dir,  recursive = TRUE, showWarnings = FALSE)

#data directories
collected_dir           <- file.path(project_root, "data", "collected")   # data as it arrived — READ-ONLY
raw_dir                 <- file.path(project_root, "data", "raw")          # data after preprocessing — READ-ONLY
processed_dir           <- file.path(project_root, "data", "processed")    # surviving data after exclusions
dir.create(raw_dir,               recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir,         recursive = TRUE, showWarnings = FALSE)

# Renders empty report cells as blanks rather than "NA".
options(knitr.kable.NA = "")



#### COLLECTED DATA ####

# 1. Read and row-bind collected CSVs, tag each row with time.
source(file.path(code_dir, "01_read_collected.R"))

# 2. Describe collected data as it arrived -> output/collected/02_summary-collected-data.html.
source(file.path(code_dir, "02_describe_collected.R"))


#### RAW DATA ####

# 3. Build raw data: split the long-format collected log into tidy CSVs, apply
# type coercion, write each to data/raw/, and write each a numbered
# NN_data-type-validation-<name>-raw.html under output/raw/.
source(file.path(code_dir, "03_build_raw_helpers.R"))
source(file.path(code_dir, "04_build_cbcu_raw.R"))
source(file.path(code_dir, "05_build_cbcu_quizz_raw.R"))
source(file.path(code_dir, "06_build_phq9_raw.R"))
source(file.path(code_dir, "07_build_feedback_raw.R"))
source(file.path(code_dir, "08_build_demographics_raw.R"))

#### PROCESSED DATA ####

# Exclude participants who did not have both sessions (time1 and time2).
source(file.path(code_dir, "10_exclude_participants_missing_session.R"))

# Exclude participants who left the window twice or more, or for more than 30
# seconds total, on either time1 or time2, during PHQ9 or CBCU.
window_exit_max    <- 2
max_window_left_ms <- 30000
source(file.path(code_dir, "11_exclude_participants_window.R"))

# Exclude trials with no recorded RT or choice (no response). RT is kept
# exploratory only -- no RT-based cutoff is applied.
source(file.path(code_dir, "12_exclude_trials_rt.R"))

# Write surviving CBCU trials and PHQ rows to data/processed/.
source(file.path(code_dir, "14_write_processed_data.R"))

# Write manuscript Participants and Data treatment excerpts from the exclusion
# cascade counts.
source(file.path(code_dir, "15_write_manuscript_excerpts.R"))

