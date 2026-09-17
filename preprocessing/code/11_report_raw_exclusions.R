# reads: raw exclusion review objects · writes: exclusion count tables in memory

#### PREPARE RAW EXCLUSION COUNTS ####

participant_exclusion_counts <- tibble::tibble(
  criterion = c(
    "Starting point (all raw participants)",
    paste0(
      "Exactly ", expected_cbcu_trials,
      " CBCU pairwise trials and all ", required_phq_responses,
      " PHQ responses at both time1 and time2"
    ),
    paste0(
      "Active-task window time at or below ",
      max_active_window_left_ms / 1000, " seconds in each session"
    )
  ),
  n_omitted = c(
    NA_integer_,
    nrow(incomplete_participant_details),
    nrow(window_excluded_participant_details)
  ),
  n_remaining = c(
    length(all_review_pids),
    length(complete_review_pids),
    length(review_surviving_pids)
  )
) |>
  dplyr::mutate(
    pct_omitted = round(100 * n_omitted / dplyr::lag(n_remaining), 1)
  )

trial_exclusion_counts <- tibble::tibble(
  criterion = c(
    "Starting point (after participant screening)",
    paste0(
      "Window left on the preceding same-numbered pairwise ITI ",
      "or on the pairwise response"
    )
  ),
  n_omitted = c(NA_integer_, nrow(review_trial_window_rows)),
  n_remaining = c(
    nrow(review_trial_pool),
    nrow(review_trials_after_window)
  )
) |>
  dplyr::mutate(
    pct_omitted = round(100 * n_omitted / dplyr::lag(n_remaining), 1)
  )
