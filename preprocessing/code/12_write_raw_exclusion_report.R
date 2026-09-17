# reads: artifacts/09_raw_window_review.rds, artifacts/10_raw_trial_review.rds, artifacts/11_raw_exclusion_counts.rds · writes: reports-processed/exclusion.md

#### WRITE EXCLUSION REPORT ####

raw_window_review <- readRDS(file.path(artifacts_dir, "09_raw_window_review.rds"))
raw_trial_review <- readRDS(file.path(artifacts_dir, "10_raw_trial_review.rds"))
raw_exclusion_counts <- readRDS(file.path(artifacts_dir, "11_raw_exclusion_counts.rds"))

review_excluded_participants <- raw_window_review$review_excluded_participants
review_surviving_pids <- raw_window_review$review_surviving_pids
review_trial_window_rows <- raw_trial_review$review_trial_window_rows
review_trials_after_window <- raw_trial_review$review_trials_after_window
participant_exclusion_counts <- raw_exclusion_counts$participant_exclusion_counts
trial_exclusion_counts <- raw_exclusion_counts$trial_exclusion_counts

participant_detail_lines <- if (nrow(review_excluded_participants) == 0) {
  "No participants were excluded."
} else {
  knitr::kable(
    review_excluded_participants,
    format = "pipe",
    col.names = c("Prolific ID", "Reason")
  )
}

trial_detail_lines <- if (nrow(review_trial_window_rows) == 0) {
  "No trials were flagged."
} else {
  knitr::kable(
    review_trial_window_rows,
    format = "pipe",
    col.names = c("Prolific ID", "Time", "CBCU trial", "Reason")
  )
}

report_lines <- c(
  "# Exclusion review", "",
  "This report belongs to the processed-data stage. Participant criteria are",
  "evaluated first; trial criteria are then evaluated only among participants",
  "who survive participant screening. `data/raw/` is not altered.", "",
  "## Criteria", "",
  paste0(
    "1. Retain participants only when both time1 and time2 contain exactly ",
    expected_cbcu_trials, " CBCU pairwise trials and all ",
    required_phq_responses, " PHQ responses."
  ),
  paste0(
    "2. Among those participants, exclude a participant if active-task window ",
    "departures total more than ", max_active_window_left_ms / 1000,
    " seconds in either session. Scheduled `phase2_break` rows do not count."
  ),
  paste0(
    "3. Among surviving participants, flag a CBCU trial when `window_status` ",
    "is `left` on its preceding same-numbered pairwise ITI row or response row."
  ), "",
  "## Sequential participant removals", "",
  knitr::kable(participant_exclusion_counts, format = "pipe"), "",
  "## Excluded participant IDs and reasons", "",
  participant_detail_lines, "",
  "## Sequential trial removals", "",
  knitr::kable(trial_exclusion_counts, format = "pipe"), "",
  "## Excluded trial identifiers and reasons", "",
  trial_detail_lines, "",
  paste0(
    "**Review result: ", length(review_surviving_pids),
    " participants and ", nrow(review_trials_after_window),
    " CBCU trials remain after applying the review criteria.**"
  )
)

writeLines(report_lines, file.path(reports_processed_dir, "exclusion.md"))
