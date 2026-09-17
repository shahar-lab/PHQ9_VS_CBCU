# reads: artifacts/08_raw_participant_review.rds, artifacts/collected.rds, artifacts/time_levels.rds · writes: artifacts/09_raw_window_review.rds

#### REVIEW RAW WINDOW EXCLUSIONS ####

raw_participant_review <- readRDS(file.path(artifacts_dir, "08_raw_participant_review.rds"))
complete_review_pids <- raw_participant_review$complete_review_pids
incomplete_participant_details <- raw_participant_review$incomplete_participant_details
collected <- readRDS(file.path(artifacts_dir, "collected.rds"))
time_levels <- readRDS(file.path(artifacts_dir, "time_levels.rds"))

# ASSUMED[active-task row definition not named]: a row is active-task when phase
# or iti_phase is populated; scheduled phase2_break rows are then removed exactly
# as specified. Empty-phase setup rows are outside active-task periods.
active_window_by_session <- collected |>
  dplyr::mutate(
    prolific_id = as.character(prolific_id),
    time = as.character(time),
    phase = dplyr::coalesce(phase, ""),
    iti_phase = dplyr::coalesce(iti_phase, ""),
    window_left_ms = as.numeric(window_left_ms)
  ) |>
  dplyr::filter(
    prolific_id %in% complete_review_pids,
    (phase != "" | iti_phase != ""),
    phase != "phase2_break"
  ) |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::summarise(
    active_window_left_ms = sum(
      window_left_ms[window_status == "left"],
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  dplyr::right_join(
    tidyr::expand_grid(prolific_id = complete_review_pids, time = time_levels),
    by = c("prolific_id", "time")
  ) |>
  dplyr::mutate(
    active_window_left_ms = dplyr::coalesce(active_window_left_ms, 0)
  )

window_excluded_participant_details <- active_window_by_session |>
  dplyr::filter(active_window_left_ms > max_active_window_left_ms) |>
  dplyr::mutate(
    session_detail = paste0(time, " (", active_window_left_ms, " ms)")
  ) |>
  dplyr::group_by(prolific_id) |>
  dplyr::summarise(
    reason = paste0(
      "Active-task window time exceeded ", max_active_window_left_ms,
      " ms: ", paste(session_detail, collapse = "; ")
    ),
    .groups = "drop"
  )

review_surviving_pids <- setdiff(
  complete_review_pids,
  window_excluded_participant_details$prolific_id
)

review_excluded_participants <- dplyr::bind_rows(
  incomplete_participant_details,
  window_excluded_participant_details
) |>
  dplyr::arrange(prolific_id)

saveRDS(
  list(
    window_excluded_participant_details = window_excluded_participant_details,
    review_surviving_pids = review_surviving_pids,
    review_excluded_participants = review_excluded_participants
  ),
  file.path(artifacts_dir, "09_raw_window_review.rds")
)
