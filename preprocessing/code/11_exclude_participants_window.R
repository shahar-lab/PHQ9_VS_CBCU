# reads: artifacts/10_after_both_sessions.rds, artifacts/collected.rds, artifacts/time_levels.rds
# writes: artifacts/11_after_window_exits.rds, output/processed/exclusion.md

#### EXCLUDE PARTICIPANTS: WINDOW LEAVING DURING PHQ9 OR CBCU ####

step10      <- readRDS(file.path(artifacts_dir, "10_after_both_sessions.rds"))
collected   <- readRDS(file.path(artifacts_dir, "collected.rds"))
time_levels <- readRDS(file.path(artifacts_dir, "time_levels.rds"))

after_both_sessions_pids <- step10$after_both_sessions_pids
exclusion_report_lines   <- step10$exclusion_report_lines

# ASSUMED[PHQ9 = phq9_grid; CBCU = pairwise trials and their ITIs]: quiz, instructions,
# scheduled phase2_break, and feedback are outside this criterion.
# ASSUMED[exits counted per task, then summed within a session]: a leave during quiz
# does not stitch the last PHQ9 row onto the first CBCU row.
# ASSUMED[NA window_status means no leave was logged]: treated as ok.
phq9_cbc_rows <- collected |>
  mutate(
    prolific_id    = as.character(prolific_id),
    time           = as.character(time),
    phase          = coalesce(phase, ""),
    iti_phase      = coalesce(iti_phase, ""),
    window_status  = if_else(is.na(window_status), "ok", window_status),
    window_left_ms = as.numeric(window_left_ms),
    time_elapsed   = as.numeric(time_elapsed)
  ) |>
  filter(
    prolific_id %in% after_both_sessions_pids,
    phase == "phq9_grid" | phase == "pairwise" | iti_phase == "pairwise"
  ) |>
  mutate(task = if_else(phase == "phq9_grid", "PHQ9", "CBCU"))

window_by_session <- phq9_cbc_rows |>
  arrange(prolific_id, time, task, time_elapsed) |>
  group_by(prolific_id, time, task) |>
  mutate(
    left_window = window_status == "left",
    exit_starts = left_window & !lag(left_window, default = FALSE)
  ) |>
  summarise(
    n_window_exits = sum(exit_starts),
    time_away_ms   = sum(window_left_ms[left_window], na.rm = TRUE),
    .groups = "drop"
  ) |>
  group_by(prolific_id, time) |>
  summarise(
    n_window_exits = sum(n_window_exits),
    time_away_ms   = sum(time_away_ms),
    .groups = "drop"
  ) |>
  right_join(
    expand_grid(prolific_id = after_both_sessions_pids, time = time_levels),
    by = c("prolific_id", "time")
  ) |>
  mutate(
    n_window_exits = coalesce(n_window_exits, 0),
    time_away_ms   = coalesce(time_away_ms, 0)
  )

failing_sessions <- window_by_session |>
  filter(n_window_exits > window_exit_max | time_away_ms > max_window_left_ms)

excluded_participant_details <- failing_sessions |>
  mutate(
    session_detail = paste0(
      time, " (", n_window_exits, " exits; ",
      round(time_away_ms / 1000, 1), " s)"
    )
  ) |>
  group_by(prolific_id) |>
  summarise(
    reason = paste0(
      "Left the window twice or more, or more than ",
      max_window_left_ms / 1000,
      " s total, during PHQ9 or CBCU: ",
      paste(session_detail, collapse = "; ")
    ),
    .groups = "drop"
  )

after_window_exits_pids <- setdiff(
  after_both_sessions_pids,
  excluded_participant_details$prolific_id
)
n_started  <- length(after_both_sessions_pids)
n_excluded <- nrow(excluded_participant_details)
n_left     <- length(after_window_exits_pids)

window_criterion_text <- paste0(
  "Left the window twice or more, or more than ",
  max_window_left_ms / 1000,
  " seconds total, on either time1 or time2, during PHQ9 or CBCU"
)

exclusion_report_lines <- c(
  exclusion_report_lines,
  paste0(
    "2. ", window_criterion_text, ". Started with ", n_started,
    " participants, excluded ", n_excluded, ", ", n_left, " left."
  )
)

writeLines(exclusion_report_lines, file.path(output_processed_dir, "exclusion.md"))

saveRDS(
  list(
    after_both_sessions_pids     = after_both_sessions_pids,
    after_window_exits_pids      = after_window_exits_pids,
    excluded_participant_details = excluded_participant_details,
    window_by_session            = window_by_session,
    window_criterion_text        = window_criterion_text,
    exclusion_report_lines       = exclusion_report_lines
  ),
  file.path(artifacts_dir, "11_after_window_exits.rds")
)
