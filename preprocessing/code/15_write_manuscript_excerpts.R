# reads: artifacts/10_after_both_sessions.rds, artifacts/11_after_window_exits.rds,
#        artifacts/12_after_rt_bounds.rds, data/raw/demographics.csv
# writes: output/processed/15_participants_excerpt.md,
#         output/processed/15_data_treatment_excerpt.md

#### WRITE MANUSCRIPT EXCERPTS ####

if (!exists("window_exit_max"))    window_exit_max    <- 2
if (!exists("max_window_left_ms")) max_window_left_ms <- 30000

step10 <- readRDS(file.path(artifacts_dir, "10_after_both_sessions.rds"))
step11 <- readRDS(file.path(artifacts_dir, "11_after_window_exits.rds"))
step12 <- readRDS(file.path(artifacts_dir, "12_after_rt_bounds.rds"))
demographics <- read_csv(file.path(raw_dir, "demographics.csv"), show_col_types = FALSE)

n_recruited    <- length(step10$all_pids)
n_missing      <- n_recruited - length(step10$after_both_sessions_pids)
n_window       <- length(step11$after_both_sessions_pids) - length(step11$after_window_exits_pids)
n_trials_in    <- nrow(step12$after_window_cbcu)
n_trials_out   <- n_trials_in - nrow(step12$after_rt_bounds)
pct_trials_out <- round(100 * n_trials_out / n_trials_in, 1)
n_final        <- length(step12$after_window_exits_pids)
n_final_trials <- nrow(step12$after_rt_bounds)
mean_trials    <- round(n_final_trials / n_final, 2)

final_demo <- demographics |>
  mutate(prolific_id = as.character(prolific_id)) |>
  filter(prolific_id %in% step12$after_window_exits_pids)

n_female <- sum(final_demo$Sex == "Female", na.rm = TRUE)
n_male   <- sum(final_demo$Sex == "Male", na.rm = TRUE)
age_mean <- round(mean(final_demo$Age, na.rm = TRUE), 1)
age_sd   <- round(sd(final_demo$Age, na.rm = TRUE), 1)
age_min  <- min(final_demo$Age, na.rm = TRUE)
age_max  <- max(final_demo$Age, na.rm = TRUE)

participants_people <- function(n) {
  if (n == 1) "1 participant" else paste0(n, " participants")
}

participants_excerpt <- paste0(
  "*Participants. ", n_recruited,
  " adults were recruited via Prolific and completed at least one session of an ",
  "online two-session study. The final sample included ", n_final,
  " participants (", n_female, " female, ", n_male, " male; mean age ",
  age_mean, " years, SD ", age_sd, ", range ", age_min, "–", age_max, ").*"
)

data_treatment_excerpt <- paste0(
  "*Data treatment. During data preprocessing we excluded ",
  participants_people(n_missing),
  " who did not complete both sessions. We then excluded participants who left ",
  "the study window more than ", window_exit_max, " times, or for more than ",
  max_window_left_ms / 1000,
  " seconds in total, during PHQ-9 or CBCU on either session (",
  participants_people(n_window), " excluded). From the remaining CBCU ",
  "observations we omitted trials with a missing RT or choice (",
  format(n_trials_out, big.mark = ","), " trials, ", pct_trials_out,
  "% of remaining trials). No RT-based trial or participant exclusion was ",
  "applied; RT was examined only descriptively. This resulted in ",
  format(n_final_trials, big.mark = ","), " CBCU trials across ", n_final,
  " participants (mean ", mean_trials, " trials per participant).*"
)

writeLines(
  c("# Participants", "", participants_excerpt),
  file.path(output_processed_dir, "15_participants_excerpt.md")
)
writeLines(
  c("# Data treatment", "", data_treatment_excerpt),
  file.path(output_processed_dir, "15_data_treatment_excerpt.md")
)
