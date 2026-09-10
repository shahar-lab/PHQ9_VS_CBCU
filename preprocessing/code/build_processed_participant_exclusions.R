#### CRITERION 1: MISSING A SESSION ####

sessions_present <- pairwise |>
  dplyr::distinct(prolific_pid, time) |>
  dplyr::count(prolific_pid, name = "n_sessions")

missing_session_pids <- sessions_present |>
  dplyr::filter(n_sessions < 2) |>
  dplyr::pull(prolific_pid)

#### CRITERION 2: TOO MANY WINDOW EXITS (reuses window_departure_table, from `collected`) ####

window_exit_pids <- window_departure_table |>
  dplyr::filter(n_departures > 2) |>
  dplyr::distinct(prolific_pid) |>
  dplyr::pull(prolific_pid)

#### CRITERION 3: TOO MANY TRIALS WOULD BE EXCLUDED (two-pass) ####

would_exclude_rate <- pairwise |>
  dplyr::mutate(
    would_exclude = is.na(rt) | is.na(choice) | rt < rt_fast_cutoff_ms | rt > rt_slow_cutoff_ms
  ) |>
  dplyr::group_by(prolific_pid, time) |>
  dplyr::summarise(pct_would_exclude = 100 * mean(would_exclude), .groups = "drop")

high_exclusion_rate_pids <- would_exclude_rate |>
  dplyr::filter(pct_would_exclude > 40) |>
  dplyr::distinct(prolific_pid) |>
  dplyr::pull(prolific_pid)

#### CRITERION 4: QUIZ COMPREHENSION (>=3 of 6 questions needed more than one attempt) ####

quiz_attempt_num_clean <- ifelse(cbcu_quizz$quiz_attempt_num %in% c("NA", ""), NA, cbcu_quizz$quiz_attempt_num)
cbcu_quizz$quiz_attempt_num_num <- as.numeric(quiz_attempt_num_clean)

quiz_retry_counts <- cbcu_quizz |>
  dplyr::group_by(prolific_pid, study_session, quiz_question_num) |>
  # ASSUMED[no criterion given for unreached/missing quiz_attempt_num]: treated as NOT needing a
  # retry (FALSE) rather than propagating NA, since an unreached question cannot have been
  # attempted more than once.
  dplyr::summarise(needed_retry = any(quiz_attempt_num_num > 1, na.rm = TRUE), .groups = "drop") |>
  dplyr::group_by(prolific_pid, study_session) |>
  dplyr::summarise(n_retry_questions = sum(needed_retry), .groups = "drop")

quiz_comprehension_pids <- quiz_retry_counts |>
  dplyr::filter(n_retry_questions >= 3) |>
  dplyr::distinct(prolific_pid) |>
  dplyr::pull(prolific_pid)

#### COMBINE: ALL REASONS PER EXCLUDED PARTICIPANT ####

exclusion_reasons <- dplyr::bind_rows(
  tibble::tibble(prolific_pid = missing_session_pids,      reason = "missing_session"),
  tibble::tibble(prolific_pid = window_exit_pids,           reason = "window_exits"),
  tibble::tibble(prolific_pid = high_exclusion_rate_pids,   reason = "trial_exclusion_rate"),
  tibble::tibble(prolific_pid = quiz_comprehension_pids,    reason = "quiz_comprehension")
)

excluded_participants <- exclusion_reasons |>
  dplyr::group_by(prolific_pid) |>
  dplyr::summarise(reasons = paste(reason, collapse = ", "), .groups = "drop")

all_pids <- pairwise |> dplyr::distinct(prolific_pid) |> dplyr::pull(prolific_pid)
included_participants <- setdiff(all_pids, excluded_participants$prolific_pid)
