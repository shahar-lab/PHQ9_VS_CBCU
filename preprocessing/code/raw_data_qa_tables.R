#### TABLE: RT OUTLIER SUMMARY ####

rt_outlier_table <- pairwise |>
  dplyr::group_by(prolific_pid, time) |>
  dplyr::summarise(
    n_trials = dplyr::n(),
    n_fast = sum(rt < rt_fast_cutoff_ms, na.rm = TRUE),
    pct_fast = round(100 * n_fast / n_trials, 1),
    n_slow = sum(rt > rt_slow_cutoff_ms, na.rm = TRUE),
    pct_slow = round(100 * n_slow / n_trials, 1),
    .groups = "drop"
  )

#### TABLE: SKIPPED-TRIAL SUMMARY ("Neither bothered me" — a legitimate response, not missing data) ####

skipped_table <- pairwise |>
  dplyr::group_by(prolific_pid, time) |>
  dplyr::summarise(
    n_trials = dplyr::n(),
    n_skipped = sum(skipped, na.rm = TRUE),
    pct_skipped = round(100 * n_skipped / n_trials, 1),
    .groups = "drop"
  )

#### TABLE: TRUE MISSING-DATA CHECK (rt or choice NA — distinct from skipped) ####

missing_table <- pairwise |>
  dplyr::group_by(prolific_pid, time) |>
  dplyr::summarise(
    n_trials = dplyr::n(),
    n_missing_rt = sum(is.na(rt)),
    n_missing_choice = sum(is.na(choice)),
    .groups = "drop"
  )

#### TABLE: TRIAL-COUNT SANITY CHECK ####

expected_pairwise_trials <- 105

trial_count_table <- pairwise |>
  dplyr::group_by(prolific_pid, time) |>
  dplyr::summarise(n_trials_found = dplyr::n(), .groups = "drop") |>
  dplyr::mutate(
    expected = expected_pairwise_trials,
    mismatch = n_trials_found != expected
  )
