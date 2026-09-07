#### TABLE: RT OUTLIER SUMMARY ####

rt_outlier_table <- pairwise |>
  dplyr::group_by(prolific_pid, study_session) |>
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
  dplyr::group_by(prolific_pid, study_session) |>
  dplyr::summarise(
    n_trials = dplyr::n(),
    n_skipped = sum(skipped == "true", na.rm = TRUE),
    pct_skipped = round(100 * n_skipped / n_trials, 1),
    .groups = "drop"
  )

#### TABLE: TRUE MISSING-DATA CHECK (rt or chosen_side NA — distinct from skipped) ####

missing_table <- pairwise |>
  dplyr::group_by(prolific_pid, study_session) |>
  dplyr::summarise(
    n_trials = dplyr::n(),
    n_missing_rt = sum(is.na(rt)),
    n_missing_choice = sum(is.na(chosen_side)),
    .groups = "drop"
  )

#### TABLE: TRIAL-COUNT SANITY CHECK ####

expected_pairwise_trials <- 105

trial_count_table <- pairwise |>
  dplyr::group_by(prolific_pid, study_session) |>
  dplyr::summarise(n_trials_found = dplyr::n(), .groups = "drop") |>
  dplyr::mutate(
    expected = expected_pairwise_trials,
    mismatch = n_trials_found != expected
  )

#### TABLE: WINDOW-DEPARTURE SUMMARY (from `collected`, all phases) ####

# ASSUMED[window_status marks a per-row state, not a discrete event]: a "departure" is
# counted as the start of a contiguous run of non-"ok" rows per subject/session, using row
# order within `collected` as the timeline; total/mean window_left_ms are summed/averaged
# only over the non-"ok" rows.
# ASSUMED[no logging criterion given for window_status]: window_status arrives directly from
# the raw jsPsych window-focus tracker, not something our pipeline constructs; an NA there
# means no departure event was logged for that row, not an unknown/ambiguous state, so NA is
# treated as "ok" (safe default: undercounts a possible unlogged departure rather than
# fabricating one from missingness).
window_departure_table <- collected |>
  dplyr::mutate(window_status = ifelse(is.na(window_status), "ok", window_status)) |>
  dplyr::group_by(prolific_pid, study_session) |>
  dplyr::mutate(away = window_status != "ok", new_departure = away & !dplyr::lag(away, default = FALSE)) |>
  dplyr::summarise(
    n_departures = sum(new_departure),
    n_away_rows = sum(away),
    total_window_left_ms = ifelse(n_away_rows == 0, 0, sum(window_left_ms[away], na.rm = TRUE)),
    mean_window_left_ms = ifelse(n_away_rows == 0, 0, round(mean(window_left_ms[away], na.rm = TRUE), 1)),
    .groups = "drop"
  ) |>
  dplyr::select(-n_away_rows)

#### RENDER TABLE PAGE HELPER (repeated across 5 small tables — one shared pattern) ####

render_table_page <- function(df, title) {
  grid::grid.newpage()
  grid::grid.text(title, y = 0.97, gp = grid::gpar(fontsize = 14, fontface = "bold"))
  if (nrow(df) == 0) {
    # ASSUMED[no message wording given]: tableGrob() cannot render a zero-row data frame,
    # so a zero-row (but valid) table falls back to a generic one-line notice instead.
    grid::grid.text("No rows to display.", y = 0.5, gp = grid::gpar(fontsize = 12, fontface = "italic"))
    return(invisible(NULL))
  }
  table_grob <- gridExtra::tableGrob(df, rows = NULL)
  gridExtra::grid.arrange(table_grob, top = "", newpage = FALSE)
}
