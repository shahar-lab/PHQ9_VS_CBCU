#### TRIAL EXCLUSIONS TABLE (only participants who survived participant phase) ####

trial_exclusions <- tibble::tibble(
  criterion = c("Starting point (after participant exclusions)",
                "No response recorded",
                paste0("RT under ", rt_fast_cutoff_ms, "ms or over ", rt_slow_cutoff_ms, "ms")),
  n_omitted = c(NA_integer_,
                nrow(after_participant_exclusions) - nrow(after_missing),
                nrow(after_missing) - nrow(after_slow_rt)),
  n_remaining = c(nrow(after_participant_exclusions), nrow(after_missing), nrow(after_slow_rt))
) |>
  dplyr::mutate(pct_omitted = round(100 * n_omitted / dplyr::lag(n_remaining), 1))

#### PER PARTICIPANT AFTER EXCLUSION: RETAINED N_TRIALS + BREAKDOWN OF % EXCLUDED ####

original_trial_counts <- after_participant_exclusions |>
  dplyr::count(prolific_pid, study_session, name = "n_trials_original")

trial_reason <- after_participant_exclusions |>
  dplyr::mutate(
    reason = dplyr::case_when(
      is.na(rt) | is.na(chosen_side)  ~ "missing",
      rt < rt_fast_cutoff_ms          ~ "fast",
      rt > rt_slow_cutoff_ms          ~ "slow",
      TRUE                            ~ "kept"
    )
  )

per_participant_after_exclusion <- trial_reason |>
  dplyr::group_by(prolific_pid, study_session) |>
  dplyr::summarise(
    n_trials = sum(reason == "kept"),
    pct_excluded_missing = 100 * mean(reason == "missing"),
    pct_excluded_fast    = 100 * mean(reason == "fast"),
    pct_excluded_slow    = 100 * mean(reason == "slow"),
    .groups = "drop"
  ) |>
  dplyr::left_join(original_trial_counts, by = c("prolific_pid", "study_session")) |>
  dplyr::mutate(
    pct_excluded_total = round(pct_excluded_missing + pct_excluded_fast + pct_excluded_slow, 1),
    pct_excluded_missing = round(pct_excluded_missing, 1),
    pct_excluded_fast    = round(pct_excluded_fast, 1),
    pct_excluded_slow    = round(pct_excluded_slow, 1)
  ) |>
  dplyr::select(prolific_pid, study_session, n_trials,
                pct_excluded_total, pct_excluded_missing, pct_excluded_fast, pct_excluded_slow)

#### APPEND TO MARKDOWN REPORT ####

report_lines <- c(
  "", "## Trial exclusions (counts in observations)", "",
  knitr::kable(trial_exclusions, format = "pipe"), "",
  paste0("**Final: ", format(nrow(cbcu_results_processed), big.mark = ","),
         " observations across ", dplyr::n_distinct(cbcu_results_processed$prolific_pid),
         " participants.**"), "",
  "## Per participant after exclusion", "",
  "Percentages are of that session's original pairwise trial count, and",
  "`pct_excluded_missing` + `pct_excluded_fast` + `pct_excluded_slow` = `pct_excluded_total`.", "",
  knitr::kable(per_participant_after_exclusion, format = "pipe")
)

report_path <- file.path(output_dir, "raw-to-processed-report.md")
write(report_lines, file = report_path, append = TRUE, sep = "\n")
