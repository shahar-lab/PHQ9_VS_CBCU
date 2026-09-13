#### PARTICIPANT EXCLUSIONS TABLE (independent criteria, not a sequential cascade) ####

n_starting <- dplyr::n_distinct(pairwise$prolific_id)

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

#### WRITE HTML REPORT (STARTS THE FILE) ####

report_css <- "
body { font-family: -apple-system, Segoe UI, Helvetica, Arial, sans-serif;
       max-width: 1100px; margin: 2rem auto; padding: 0 1rem; color: #222; }
h1 { border-bottom: 2px solid #333; padding-bottom: 0.3rem; }
h2 { margin-top: 2rem; color: #333; }
table { border-collapse: collapse; margin: 0.5rem 0 1.5rem; font-size: 0.9rem; }
th, td { border: 1px solid #ddd; padding: 4px 10px; text-align: left; white-space: nowrap; }
thead th, tr:has(> th) { background: #333; color: #fff; }
tbody tr:nth-child(even) { background: #f6f6f6; }
tbody tr:hover { background: #eef4fb; }
"

report_html <- c(
  "<html><head><meta charset=\"UTF-8\"><title>Raw-to-processed report</title>",
  paste0("<style>", report_css, "</style></head><body>"),
  "<h1>Raw-to-processed report</h1>",
  "<p>Built by <code>preprocessing/code/build_processed_participant_exclusions.R</code> and",
  "<code>build_processed_trial_exclusions.R</code>. Participant criteria run first, then trial",
  "criteria on the participants that remain.</p>",
  "<p><strong>Note:</strong> the four participant criteria below are independent checks evaluated",
  "per-session (not a sequential cascade) — a participant tripping any one of them is",
  "excluded entirely, and may trip more than one, so <code>n_omitted</code> counts can overlap across",
  "rows and will not sum to the total number of participants excluded. See the excluded-",
  "participants list below for the full per-participant reason set.</p>",
  "<h2>Participant exclusions (counts in participants)</h2>",
  knitr::kable(participant_exclusions, format = "html"),
  "<h2>Excluded participants</h2>",
  knitr::kable(excluded_participants, format = "html")
)

report_path <- file.path(output_dir, "processed_related_reports", "raw-to-processed-report.html")
writeLines(report_html, report_path)
