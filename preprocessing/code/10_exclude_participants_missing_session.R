# reads: artifacts/time_levels.rds, data/raw/cbcu_results.csv, data/raw/phq9_results.csv
# writes: artifacts/10_after_both_sessions.rds, output/processed/exclusion.md

#### EXCLUDE PARTICIPANTS: MISSING A SESSION ####

time_levels  <- readRDS(file.path(artifacts_dir, "time_levels.rds"))
cbcu_results <- read_csv(file.path(raw_dir, "cbcu_results.csv"), show_col_types = FALSE)
phq9_results <- read_csv(file.path(raw_dir, "phq9_results.csv"), show_col_types = FALSE)

all_pids <- union(
  as.character(cbcu_results$prolific_id),
  as.character(phq9_results$prolific_id)
)

# ASSUMED[both sessions = present at time1 and time2]: presence is the union of
# raw CBCU and PHQ9 rows, so a participant who returned for either task counts
# as having that session.
session_presence <- bind_rows(
  transmute(
    cbcu_results,
    prolific_id = as.character(prolific_id),
    time        = as.character(time)
  ),
  transmute(
    phq9_results,
    prolific_id = as.character(prolific_id),
    time        = as.character(time)
  )
) |>
  distinct() |>
  filter(time %in% time_levels)

n_sessions <- session_presence |>
  count(prolific_id, name = "n_sessions")

excluded_participant_details <- n_sessions |>
  filter(n_sessions < length(time_levels)) |>
  transmute(
    prolific_id,
    reason = "Did not have both sessions"
  )

after_both_sessions_pids <- setdiff(all_pids, excluded_participant_details$prolific_id)
n_started  <- length(all_pids)
n_excluded <- nrow(excluded_participant_details)
n_left     <- length(after_both_sessions_pids)

both_sessions_criterion_text <- "Did not have both sessions"

exclusion_report_lines <- c(
  "# Exclusion summary",
  "",
  paste0(
    "1. ", both_sessions_criterion_text, ". Started with ", n_started,
    " participants, excluded ", n_excluded, ", ", n_left, " left."
  )
)

writeLines(exclusion_report_lines, file.path(output_processed_dir, "exclusion.md"))

saveRDS(
  list(
    all_pids                     = all_pids,
    after_both_sessions_pids     = after_both_sessions_pids,
    excluded_participant_details = excluded_participant_details,
    both_sessions_criterion_text = both_sessions_criterion_text,
    exclusion_report_lines       = exclusion_report_lines
  ),
  file.path(artifacts_dir, "10_after_both_sessions.rds")
)
