rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(jsonlite)
library(gridExtra)

project_root  <- here::here()
code_dir      <- file.path(project_root, "preprocessing", "code")
output_dir    <- file.path(project_root, "preprocessing", "output")
collected_dir <- file.path(project_root, "data", "collected")   # data as it arrived — READ-ONLY
raw_dir       <- file.path(project_root, "data", "raw")
processed_dir <- file.path(project_root, "data", "processed")

if (!dir.exists(output_dir))    dir.create(output_dir, recursive = TRUE)
if (!dir.exists(raw_dir))       dir.create(raw_dir, recursive = TRUE)
if (!dir.exists(processed_dir)) dir.create(processed_dir, recursive = TRUE)

# Renders empty report cells as blanks rather than "NA".
options(knitr.kable.NA = "")



#### COLLECTED DATA ####

# 1. Read and row-bind collected CSVs, tag each row with time.
source(file.path(code_dir, "read_collected.R"))

# 2. Describe collected data as it arrived -> summary-collected-data.md/.html.
source(file.path(code_dir, "describe_collected.R"))

#### RAW DATA ####

# 3. Build raw data: split the long-format collected log into tidy CSVs, apply
# type coercion, write each to data/raw/, and write each a
# data-type-validation-<name>-raw.html (head of data + numeric/categorical/dictionary).
source(file.path(code_dir, "build_raw_helpers.R"))
source(file.path(code_dir, "build_cbcu_raw.R"))
source(file.path(code_dir, "build_cbcu_quizz_raw.R"))
source(file.path(code_dir, "build_phq9_raw.R"))
source(file.path(code_dir, "build_feedback_raw.R"))

# 4. Build demographics raw: exclude returned participants, drop the
# completion code column, write demographics.csv to data/raw/, and write
# data-type-validation-demographics-raw.html.
source(file.path(code_dir, "build_demographics_raw.R"))

# 5. Exploratory QA report on CBCU pairwise raw data: RT plots, outlier/skip/
# missing/window-departure/trial-count tables, written as a single multi-page
# PDF to preprocessing/output/raw_data_qa_report.pdf.
source(file.path(code_dir, "raw_data_qa_plots.R"))
source(file.path(code_dir, "raw_data_qa_tables.R"))
source(file.path(code_dir, "raw_data_qa_tables_window_departure.R"))
source(file.path(code_dir, "raw_data_qa_report.R"))

# 6. Build processed CBCU data: participant-level exclusions (missing session,
# window exits, trial-exclusion rate, quiz comprehension), then trial-level
# exclusions (missing rt/choice, fast/slow RT) on survivors, writing
# data/processed/cbcu_results.csv and the markdown + PDF exclusion reports.
source(file.path(code_dir, "build_processed_participant_exclusions.R"))
source(file.path(code_dir, "build_processed_trial_exclusions.R"))
source(file.path(code_dir, "build_processed_report_md_participants.R"))
source(file.path(code_dir, "build_processed_report_md_trials.R"))
source(file.path(code_dir, "build_processed_report_pdf.R"))

# 7. Build the manuscript "Data treatment" paragraph: trial-omission and
# participant-exclusion statistics computed from the pipeline's own objects,
# rendered as a single-page PDF to preprocessing/output/.
source(file.path(code_dir, "build_data_treatment_paragraph.R"))
