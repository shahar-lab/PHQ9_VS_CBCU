rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(jsonlite)
library(gridExtra)
library(hms)
library(plotly)
library(htmlwidgets)
library(htmltools)

project_root            <- here::here()
preprocessing_dir       <- file.path(project_root, "preprocessing")
code_dir                <- file.path(preprocessing_dir, "code")
artifacts_dir           <- file.path(preprocessing_dir, "artifacts")
output_dir              <- file.path(preprocessing_dir, "output")
reports_collected_dir   <- file.path(output_dir, "reports-collected")
reports_raw_dir         <- file.path(output_dir, "reports-raw")
reports_processed_dir   <- file.path(output_dir, "reports-processed")
collected_dir           <- file.path(project_root, "data", "collected")   # data as it arrived — READ-ONLY
raw_dir                 <- file.path(project_root, "data", "raw")
processed_dir           <- file.path(project_root, "data", "processed")

expected_cbcu_trials          <- 105
required_phq_responses        <- 9
max_active_window_left_ms     <- 30000

dir.create(artifacts_dir,         recursive = TRUE, showWarnings = FALSE)
dir.create(reports_collected_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(reports_raw_dir,       recursive = TRUE, showWarnings = FALSE)
dir.create(reports_processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(raw_dir,               recursive = TRUE, showWarnings = FALSE)
dir.create(processed_dir,         recursive = TRUE, showWarnings = FALSE)

# Renders empty report cells as blanks rather than "NA".
options(knitr.kable.NA = "")



#### COLLECTED DATA ####

# 1. Read and row-bind collected CSVs, tag each row with time.
source(file.path(code_dir, "01_read_collected.R"))

# 2. Describe collected data as it arrived -> reports-collected/02_summary-collected-data.html.
source(file.path(code_dir, "02_describe_collected.R"))



#### RAW DATA ####

# 3. Build raw data: split the long-format collected log into tidy CSVs, apply
# type coercion, write each to data/raw/, and write each a numbered
# NN_data-type-validation-<name>-raw.html under reports-raw/.
source(file.path(code_dir, "03_build_raw_helpers.R"))
source(file.path(code_dir, "04_build_cbcu_raw.R"))
source(file.path(code_dir, "05_build_cbcu_quizz_raw.R"))
source(file.path(code_dir, "06_build_phq9_raw.R"))
source(file.path(code_dir, "07_build_feedback_raw.R"))

# Plot every raw CBCU RT against trial number. Raw data are not filtered here.
source(file.path(code_dir, "14_plot_raw_cbcu_rt_by_trial_interactive.R"))

#### PROCESSED DATA ####


# 3b. Build processed PHQ9 data: add phq9_sum (row-wise total, NA if any item is
# missing) to phq9_results, no exclusions, write data/processed/phq9_results.csv
# and reports-processed/ data-type-validation-phq9-processed.html.
source(file.path(code_dir, "build_processed_phq9.R"))

# 4. Build demographics raw: exclude returned participants, drop the
# completion code column, write demographics.csv to data/raw/, and write
# data-type-validation-demographics-raw.html under reports-raw/.
source(file.path(code_dir, "build_demographics_raw.R"))

# Review participant/trial exclusions on the raw tables without changing
# data/raw/; write the review report under reports-processed/.
source(file.path(code_dir, "08_review_raw_participant_exclusions.R"))
source(file.path(code_dir, "09_review_raw_window_exclusions.R"))
source(file.path(code_dir, "10_review_raw_trial_exclusions.R"))
source(file.path(code_dir, "11_report_raw_exclusions.R"))
source(file.path(code_dir, "12_write_raw_exclusion_report.R"))

# 5. Exploratory QA report on CBCU pairwise raw data: RT plots, outlier/skip/
# missing/window-departure/trial-count tables, written as a single multi-page
# PDF to preprocessing/output/reports-raw/raw_data_qa_report.pdf.
source(file.path(code_dir, "raw_data_qa_plots.R"))
source(file.path(code_dir, "raw_data_qa_tables.R"))
source(file.path(code_dir, "raw_data_qa_tables_window_departure.R"))
source(file.path(code_dir, "raw_data_qa_report.R"))

# 6. Build processed CBCU data: participant-level exclusions (missing session,
# window exits, trial-exclusion rate, quiz comprehension), then trial-level
# exclusions (missing rt/choice, fast/slow RT) on survivors, writing
# data/processed/cbcu_results.csv and the HTML + PDF exclusion reports.
source(file.path(code_dir, "build_processed_participant_exclusions.R"))
source(file.path(code_dir, "build_processed_trial_exclusions.R"))
source(file.path(code_dir, "build_processed_report_md_participants.R"))
source(file.path(code_dir, "build_processed_report_md_trials.R"))
source(file.path(code_dir, "build_processed_report_pdf.R"))

# 7. Build the manuscript "Data treatment" paragraph: trial-omission and
# participant-exclusion statistics computed from the pipeline's own objects,
# rendered as a single-page PDF to preprocessing/output/reports-processed/.
source(file.path(code_dir, "build_data_treatment_paragraph.R"))

