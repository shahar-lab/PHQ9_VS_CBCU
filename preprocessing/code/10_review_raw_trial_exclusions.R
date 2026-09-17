# reads: artifacts/09_raw_window_review.rds, artifacts/collected.rds, data/raw/cbcu_results.csv · writes: artifacts/10_raw_trial_review.rds

#### REVIEW RAW TRIAL EXCLUSIONS ####

raw_window_review <- readRDS(file.path(artifacts_dir, "09_raw_window_review.rds"))
review_surviving_pids <- raw_window_review$review_surviving_pids
collected <- readRDS(file.path(artifacts_dir, "collected.rds"))
cbcu_results <- read_csv(file.path(raw_dir, "cbcu_results.csv"), show_col_types = FALSE)

review_trial_pool <- cbcu_results |>
  dplyr::mutate(
    prolific_id = as.character(prolific_id),
    time = as.character(time)
  ) |>
  dplyr::filter(prolific_id %in% review_surviving_pids)

review_trial_window_rows <- collected |>
  dplyr::mutate(
    prolific_id = as.character(prolific_id),
    time = as.character(time),
    phase = dplyr::coalesce(phase, ""),
    iti_phase = dplyr::coalesce(iti_phase, ""),
    trial = as.numeric(phase_trial_num)
  ) |>
  dplyr::filter(
    prolific_id %in% review_surviving_pids,
    !is.na(trial),
    phase == "pairwise" | iti_phase == "pairwise"
  ) |>
  dplyr::group_by(prolific_id, time, trial) |>
  dplyr::summarise(
    left_on_preceding_iti = any(
      window_status == "left" & iti_phase == "pairwise",
      na.rm = TRUE
    ),
    left_on_response = any(
      window_status == "left" & phase == "pairwise",
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  dplyr::filter(left_on_preceding_iti | left_on_response) |>
  dplyr::mutate(
    reason = dplyr::case_when(
      left_on_preceding_iti & left_on_response ~
        "Window left on preceding pairwise ITI and pairwise response",
      left_on_preceding_iti ~
        "Window left on preceding pairwise ITI",
      TRUE ~
        "Window left on pairwise response"
    )
  ) |>
  dplyr::select(prolific_id, time, trial, reason) |>
  dplyr::arrange(prolific_id, time, trial)

review_trials_after_window <- review_trial_pool |>
  dplyr::anti_join(
    review_trial_window_rows,
    by = c("prolific_id", "time", "trial")
  )

saveRDS(
  list(
    review_trial_pool = review_trial_pool,
    review_trial_window_rows = review_trial_window_rows,
    review_trials_after_window = review_trials_after_window
  ),
  file.path(artifacts_dir, "10_raw_trial_review.rds")
)
