#### PARTICIPANT EXCLUSIONS TABLE (independent criteria, not a sequential cascade) ####

n_starting <- dplyr::n_distinct(pairwise$prolific_pid)

participant_exclusions <- tibble::tibble(
  criterion = c("Starting point (all participants)",
                "Missing a session",
                "Too many window exits (n_departures > 2 in either session)",
                paste0("Too many trials would be excluded (>40% in either session)"),
                "Quiz comprehension (>=3 of 6 questions needed a retry, either session)"),
  n_omitted = c(NA_integer_,
                length(missing_session_pids),
                length(window_exit_pids),
                length(high_exclusion_rate_pids),
                length(quiz_comprehension_pids))
) |>
  dplyr::mutate(
    # n_remaining per criterion row = participants left if ONLY that criterion were applied
    # (independent effect), not a cascading count across rows.
    n_remaining = c(n_starting,
                    n_starting - length(missing_session_pids),
                    n_starting - length(window_exit_pids),
                    n_starting - length(high_exclusion_rate_pids),
                    n_starting - length(quiz_comprehension_pids)),
    pct_omitted = round(100 * n_omitted / n_starting, 1)
  )

#### WRITE MARKDOWN REPORT (STARTS THE FILE) ####

report_lines <- c(
  "# Raw-to-processed report", "",
  "Built by `preprocessing/code/build_processed_participant_exclusions.R` and",
  "`build_processed_trial_exclusions.R`. Participant criteria run first, then trial",
  "criteria on the participants that remain.", "",
  "**Note:** the four participant criteria below are independent checks evaluated",
  "per-session (not a sequential cascade) — a participant tripping any one of them is",
  "excluded entirely, and may trip more than one, so `n_omitted` counts can overlap across",
  "rows and will not sum to the total number of participants excluded. See the excluded-",
  "participants list below for the full per-participant reason set.", "",
  "## Participant exclusions (counts in participants)", "",
  knitr::kable(participant_exclusions, format = "pipe"), "",
  "## Excluded participants", "",
  knitr::kable(excluded_participants, format = "pipe")
)

report_path <- file.path(output_dir, "raw-to-processed-report.md")
writeLines(report_lines, report_path)
