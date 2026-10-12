rm(list = ls())

#### SETUP ####

library(here)
library(tidyverse)
library(patchwork)
library(grid)
library(gridExtra)

project_root  <- here::here()
code_dir      <- file.path(project_root, "analysis", "rt_claude_exploration", "code")
artifacts_dir <- file.path(project_root, "analysis", "rt_claude_exploration", "artifacts")
output_dir    <- file.path(project_root, "analysis", "rt_claude_exploration", "output")
data_path     <- file.path(project_root, "data", "processed")
claude_dir    <- file.path(project_root, "analysis", "rt_claude_exploration")
dir.create(artifacts_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# The 15 PHQ-9 sub-items used as labels in both Claude's raw file and cbcu.csv.
phq9_item_order <- c("1", "2a", "2b", "3a", "3b", "4", "5a", "5b", "6a", "6b", "7", "8a", "8b", "9a", "9b")
n_trials_expected <- 105

# Display cap for the RT axis (ms). Trials above it are counted and reported, not removed.
rt_axis_cap <- 15000


#### EXECUTE PIPELINE ####

# Exception, approved by the researcher: Claude's raw session CSV is read directly from
# claude_dir (it never went through preprocessing). The human reference comes from data_path.

# 1. Claude's choice trials (raw file, cleaned and checked)
source(file.path(code_dir, "01_prep_claude_trials.R"))

# 2. Human reference trials (data/processed/cbcu.csv) combined with Claude's
source(file.path(code_dir, "02_prep_human_trials.R"))

# 3. Transitivity: cyclic triples per participant-session
source(file.path(code_dir, "03_transitivity.R"))

# 4. Consistency: share of choices contradicting the best single ranking
source(file.path(code_dir, "04_consistency.R"))

# 5. Table of transitivity and consistency, Claude next to the humans
source(file.path(code_dir, "05_metrics_table.R"))

# 6. RT as a function of trial
source(file.path(code_dir, "06_plot_rt_by_trial.R"))

# 7. RT distributions: Claude and each human participant (dot histograms)
source(file.path(code_dir, "07_plot_rt_distribution.R"))

# 8. PDF report with the cleaning details, figures and tables
source(file.path(code_dir, "08_write_report_pdf.R"))
