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
  dplyr::mutate(
    window_status = ifelse(is.na(window_status), "ok", window_status),
    # window_left_ms arrives as character (collected is read with col_types = "c"); clean
    # placeholder strings then coerce, following the lab's standard numeric-coercion pattern.
    window_left_ms = ifelse(window_left_ms %in% c("NA", ""), NA_real_, window_left_ms),
    window_left_ms = as.numeric(window_left_ms)
  ) |>
  dplyr::group_by(prolific_id, time) |>
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
