# reads: artifacts/11_after_window_exits.rds, data/raw/cbcu_quizz.csv
# writes: artifacts/11b_after_quiz_errors.rds, output/processed/exclusion.md,
#         output/processed/11b_quiz_errors_by_session.md

#### EXCLUDE PARTICIPANTS: TOO MANY QUIZ ERRORS IN A SESSION ####

step11     <- readRDS(file.path(artifacts_dir, "11_after_window_exits.rds"))
cbcu_quizz <- read_csv(file.path(raw_dir, "cbcu_quizz.csv"), show_col_types = FALSE)

after_window_exits_pids <- step11$after_window_exits_pids
exclusion_report_lines  <- step11$exclusion_report_lines

# An error is a quiz attempt with correct == FALSE; every wrong attempt counts, including
# repeated attempts on the same question. A session with no wrong attempt gets 0.
# ASSUMED[errors are counted per session, not summed across sessions]: more than
# quiz_error_max errors in either time1 or time2 excludes the participant.
quiz_errors_by_session <- cbcu_quizz |>
  mutate(prolific_id = as.character(prolific_id), time = as.character(time)) |>
  filter(prolific_id %in% after_window_exits_pids) |>
  group_by(prolific_id, time) |>
  summarise(n_errors = sum(!correct, na.rm = TRUE), .groups = "drop") |>
  complete(prolific_id = after_window_exits_pids, time = time_levels,
           fill = list(n_errors = 0))

failing_sessions <- quiz_errors_by_session |>
  filter(n_errors > quiz_error_max)

excluded_participant_details <- failing_sessions |>
  mutate(session_detail = paste0(time, " (", n_errors, " errors)")) |>
  group_by(prolific_id) |>
  summarise(
    reason = paste0(
      "More than ", quiz_error_max, " quiz errors in a session: ",
      paste(session_detail, collapse = "; ")
    ),
    .groups = "drop"
  )

after_quiz_errors_pids <- setdiff(
  after_window_exits_pids,
  excluded_participant_details$prolific_id
)
n_started  <- length(after_window_exits_pids)
n_excluded <- nrow(excluded_participant_details)
n_left     <- length(after_quiz_errors_pids)

quiz_error_criterion_text <- paste0(
  "More than ", quiz_error_max, " quiz errors in either time1 or time2"
)

exclusion_report_lines <- c(
  exclusion_report_lines,
  paste0(
    "3. ", quiz_error_criterion_text, ". Started with ", n_started,
    " participants, excluded ", n_excluded, ", ", n_left, " left."
  )
)

writeLines(exclusion_report_lines, file.path(output_processed_dir, "exclusion.md"))

# Table of the number of participants at each error count, per session, over everyone
# who entered this step (before the exclusion is applied).
# Error counts above quiz_error_max are pooled into one "<max+1>+" row.
overflow_label <- paste0(quiz_error_max + 1, "+")
error_levels   <- c(0:quiz_error_max, overflow_label)
quiz_error_table <- quiz_errors_by_session |>
  mutate(errors = factor(
    if_else(n_errors > quiz_error_max, overflow_label, as.character(n_errors)),
    levels = error_levels
  )) |>
  count(time, errors, .drop = FALSE) |>
  complete(time = time_levels, errors, fill = list(n = 0)) |>
  pivot_wider(names_from = time, values_from = n, names_prefix = "participants_")

# Overlap of the excluded participants between sessions.
failing_wide <- quiz_errors_by_session |>
  pivot_wider(names_from = time, values_from = n_errors) |>
  filter(if_any(all_of(time_levels), \(x) x > quiz_error_max))
quiz_error_overlap <- tibble(
  excluded_in = c("time1 only", "time2 only", "both sessions", "total excluded"),
  participants = c(
    sum(failing_wide[[time_levels[1]]] > quiz_error_max & failing_wide[[time_levels[2]]] <= quiz_error_max),
    sum(failing_wide[[time_levels[2]]] > quiz_error_max & failing_wide[[time_levels[1]]] <= quiz_error_max),
    sum(failing_wide[[time_levels[1]]] > quiz_error_max & failing_wide[[time_levels[2]]] > quiz_error_max),
    nrow(failing_wide)
  )
)

writeLines(
  c(
    "# Quiz errors by session",
    "",
    paste0(
      "Participants entering this step: ", n_started, ". Participants with more than ",
      quiz_error_max, " errors in a session (errors > ", quiz_error_max,
      ") are excluded."
    ),
    "",
    knitr::kable(quiz_error_table, format = "pipe"),
    "",
    "## Overlap of excluded participants between sessions",
    "",
    knitr::kable(quiz_error_overlap, format = "pipe")
  ),
  file.path(output_processed_dir, "11b_quiz_errors_by_session.md")
)

saveRDS(
  list(
    after_window_exits_pids      = after_window_exits_pids,
    after_quiz_errors_pids       = after_quiz_errors_pids,
    excluded_participant_details = excluded_participant_details,
    quiz_errors_by_session       = quiz_errors_by_session,
    quiz_error_criterion_text    = quiz_error_criterion_text,
    exclusion_report_lines       = exclusion_report_lines
  ),
  file.path(artifacts_dir, "11b_after_quiz_errors.rds")
)
