#### DESCRIBE: ROWS AND HOUSEKEEPING ####

row_summary_collected <- tibble::tibble(
  metric = c("Participants", "Sessions (time1)", "Sessions (time2)"),
  value  = c(dplyr::n_distinct(collected$prolific_id),
             dplyr::n_distinct(collected$prolific_id[collected$time == "time1"]),
             dplyr::n_distinct(collected$prolific_id[collected$time == "time2"]))
)

#### DESCRIBE: FORMAT SECONDS AS min:sec (shared by the PHQ9 and CBCU tables) ####

format_min_sec <- function(seconds) {
  seconds <- round(seconds)
  ifelse(is.na(seconds), NA_character_, sprintf("%d:%02d", seconds %/% 60, seconds %% 60))
}

#### DESCRIBE: PER PARTICIPANT (WINDOW EXITS) ####

# ASSUMED[same window-departure definition as raw_data_qa_tables_window_departure.R]: a
# "departure" is the start of a contiguous run of non-"ok" window_status rows per
# participant/session, using row order within `collected` as the timeline; NA window_status
# is treated as "ok" (no departure logged), and window_left_ms is summed only over away rows.
window_exits_collected <- collected |>
  dplyr::mutate(
    window_status  = ifelse(is.na(window_status), "ok", window_status),
    window_left_ms = ifelse(window_left_ms %in% c("NA", ""), NA_real_, window_left_ms),
    window_left_ms = as.numeric(window_left_ms)
  ) |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::mutate(away = window_status != "ok", new_departure = away & !dplyr::lag(away, default = FALSE)) |>
  dplyr::summarise(
    win_exit_count      = sum(new_departure),
    win_exit_total_time = ifelse(sum(away) == 0, 0, sum(window_left_ms[away], na.rm = TRUE) / 1000),
    .groups = "drop"
  )

#### DESCRIBE: OVERVIEW PER PARTICIPANT (whole session, not phase-specific) ####

# total_time is the full session wall-clock span (first to last logged row), covering
# instructions, PHQ9, quiz, CBCU, breaks and feedback together, not just one phase.
overview_per_participant <- collected |>
  dplyr::mutate(time_elapsed = as.numeric(ifelse(time_elapsed %in% c("NA", ""),
                                                   NA, time_elapsed))) |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::summarise(
    total_time = (max(time_elapsed, na.rm = TRUE) - min(time_elapsed, na.rm = TRUE)) / 1000,
    .groups = "drop"
  ) |>
  dplyr::left_join(window_exits_collected, by = c("prolific_id", "time"))

overview_table_wide <- overview_per_participant |>
  tidyr::pivot_wider(
    names_from  = time,
    values_from = c(total_time, win_exit_count, win_exit_total_time),
    names_glue  = "{time}__{.value}"
  ) |>
  dplyr::select(prolific_id,
                dplyr::starts_with("time1__"), dplyr::starts_with("time2__")) |>
  dplyr::arrange(prolific_id) |>
  dplyr::mutate(dplyr::across(dplyr::ends_with("completion_time") | dplyr::ends_with("total_time"),
                               format_min_sec))

# Markdown pipe tables have no spanning-header syntax; this table is written as HTML
# instead so time1/time2 render as a genuine merged (colspan) header row.
overview_metric_labels <- c("total_time", "win_exit_count", "win_exit_total_time")
overview_header_html <- c(
  "<tr><th></th>",
  paste0("<th colspan=\"", length(overview_metric_labels), "\">time1</th>"),
  paste0("<th colspan=\"", length(overview_metric_labels), "\">time2</th>"),
  "</tr>",
  paste0("<tr><th>prolific_id</th>",
         paste0("<th>", rep(overview_metric_labels, 2), "</th>", collapse = ""),
         "</tr>")
)

overview_cells <- overview_table_wide |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ ifelse(is.na(.x), "", as.character(.x)))) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ paste0("<td>", .x, "</td>")))
overview_table_html <- c(
  "<table>",
  overview_header_html,
  paste0("<tr>", do.call(paste0, overview_cells), "</tr>"),
  "</table>"
)

#### DESCRIBE: PHQ9 PER PARTICIPANT ####

# phq9_grid is the one row per participant/session where the PHQ9 questionnaire is
# submitted; phq_items counts how many of the 9 phq9_*_score items were answered on that
# row, and time_to_submit_ms is its completion time (converted here from ms to s).
phq9_score_cols <- paste0("phq9_", 1:9, "_score")
phq9_per_participant <- collected |>
  dplyr::filter(phase == "phq9_grid") |>
  dplyr::mutate(
    time_to_submit_ms = as.numeric(ifelse(time_to_submit_ms %in% c("NA", ""),
                                           NA, time_to_submit_ms)),
    phq_items = rowSums(!is.na(dplyr::pick(dplyr::all_of(phq9_score_cols))))
  ) |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::summarise(
    phq_items           = sum(phq_items),
    phq_completion_time = sum(time_to_submit_ms, na.rm = TRUE) / 1000,
    .groups = "drop"
  )

phq9_table_wide <- phq9_per_participant |>
  tidyr::pivot_wider(
    names_from  = time,
    values_from = c(phq_items, phq_completion_time),
    names_glue  = "{time}__{.value}"
  ) |>
  dplyr::select(prolific_id,
                dplyr::starts_with("time1__"), dplyr::starts_with("time2__")) |>
  dplyr::arrange(prolific_id) |>
  dplyr::mutate(dplyr::across(dplyr::ends_with("completion_time") | dplyr::ends_with("total_time"),
                               format_min_sec))

# Markdown pipe tables have no spanning-header syntax; this table is written as HTML
# instead so time1/time2 render as a genuine merged (colspan) header row.
phq9_metric_labels <- c("items", "completion_time")
phq9_header_html <- c(
  "<tr><th></th>",
  paste0("<th colspan=\"", length(phq9_metric_labels), "\">time1</th>"),
  paste0("<th colspan=\"", length(phq9_metric_labels), "\">time2</th>"),
  "</tr>",
  paste0("<tr><th>prolific_id</th>",
         paste0("<th>", rep(phq9_metric_labels, 2), "</th>", collapse = ""),
         "</tr>")
)

phq9_cells <- phq9_table_wide |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ ifelse(is.na(.x), "", as.character(.x)))) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ paste0("<td>", .x, "</td>")))
phq9_table_html <- c(
  "<table>",
  phq9_header_html,
  paste0("<tr>", do.call(paste0, phq9_cells), "</tr>"),
  "</table>"
)

#### DESCRIBE: CBCU PER PARTICIPANT ####

# CBCU has no single completion-time field like PHQ9's time_to_submit_ms; its completion
# time is the wall-clock span (last minus first time_elapsed, converted to seconds)
# across the pairwise-phase rows for that participant/session.
# A quiz question that's answered incorrectly is re-asked, incrementing quiz_attempt_num;
# cbcu_quiz_attempts counts every logged attempt, not distinct questions, so it can exceed
# the number of quiz questions when a participant retried one or more.
cbcu_quiz_attempts_collected <- collected |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::summarise(cbcu_quiz_attempts = sum(!is.na(quiz_question_num)), .groups = "drop")

cbcu_per_participant <- collected |>
  dplyr::filter(phase == "pairwise" | iti_phase == "pairwise") |>
  dplyr::mutate(time_elapsed = as.numeric(ifelse(time_elapsed %in% c("NA", ""),
                                                   NA, time_elapsed))) |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::summarise(
    cbcu_items           = sum(phase == "pairwise", na.rm = TRUE),
    cbcu_completion_time = (max(time_elapsed, na.rm = TRUE) - min(time_elapsed, na.rm = TRUE)) / 1000,
    .groups = "drop"
  ) |>
  dplyr::left_join(cbcu_quiz_attempts_collected, by = c("prolific_id", "time"))

cbcu_table_wide <- cbcu_per_participant |>
  tidyr::pivot_wider(
    names_from  = time,
    values_from = c(cbcu_items, cbcu_quiz_attempts, cbcu_completion_time),
    names_glue  = "{time}__{.value}"
  ) |>
  dplyr::select(prolific_id,
                dplyr::starts_with("time1__"), dplyr::starts_with("time2__")) |>
  dplyr::arrange(prolific_id) |>
  dplyr::mutate(dplyr::across(dplyr::ends_with("completion_time") | dplyr::ends_with("total_time"),
                               format_min_sec))

# Markdown pipe tables have no spanning-header syntax; this table is written as HTML
# instead so time1/time2 render as a genuine merged (colspan) header row.
cbcu_metric_labels <- c("items", "quiz_attempts", "completion_time")
cbcu_header_html <- c(
  "<tr><th></th>",
  paste0("<th colspan=\"", length(cbcu_metric_labels), "\">time1</th>"),
  paste0("<th colspan=\"", length(cbcu_metric_labels), "\">time2</th>"),
  "</tr>",
  paste0("<tr><th>prolific_id</th>",
         paste0("<th>", rep(cbcu_metric_labels, 2), "</th>", collapse = ""),
         "</tr>")
)

cbcu_cells <- cbcu_table_wide |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ ifelse(is.na(.x), "", as.character(.x)))) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ paste0("<td>", .x, "</td>")))
cbcu_table_html <- c(
  "<table>",
  cbcu_header_html,
  paste0("<tr>", do.call(paste0, cbcu_cells), "</tr>"),
  "</table>"
)

#### DESCRIBE: DEMOGRAPHICS (Prolific export) ####

# One row per participant, no session split (Prolific demographics are collected once).
# ASSUMED[not explicitly listed]: `demographics_collected` (the raw Prolific export, read in
# read_collected.R) still carries `Participant id`; renamed locally here to match the
# prolific_id naming used everywhere else in this report.
demographics_table <- demographics_collected |>
  dplyr::rename(prolific_id = `Participant id`) |>
  dplyr::select(prolific_id, Age, Sex, `Ethnicity simplified`,
                `Country of residence`, `Student status`, `Employment status`) |>
  dplyr::arrange(prolific_id)

#### WRITE COLLECTED-DATA STRUCTURE REPORT (markdown) ####

collected_report_lines <- c(
  "# Summary of collected data", "",
  "## Rows", "", knitr::kable(row_summary_collected, format = "pipe"), "",
  "## Overview", "",
  overview_table_html, "",
  "## PHQ9", "",
  phq9_table_html, "",
  "## CBCU", "",
  cbcu_table_html, "",
  "## Demographics per participant", "",
  knitr::kable(demographics_table, format = "pipe")
)
writeLines(collected_report_lines, file.path(output_dir, "summary-collected-data.md"))

#### WRITE COLLECTED-DATA STRUCTURE REPORT (html) ####

summary_report_css <- "
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

collected_report_html <- c(
  "<html><head><meta charset=\"UTF-8\"><title>Summary of collected data</title>",
  paste0("<style>", summary_report_css, "</style></head><body>"),
  "<h1>Summary of collected data</h1>",
  "<h2>Rows</h2>", knitr::kable(row_summary_collected, format = "html"),
  "<h2>Overview</h2>", overview_table_html,
  "<h2>PHQ9</h2>", phq9_table_html,
  "<h2>CBCU</h2>", cbcu_table_html,
  "<h2>Demographics per participant</h2>", knitr::kable(demographics_table, format = "html"),
  "</body></html>"
)
writeLines(collected_report_html, file.path(output_dir, "summary-collected-data.html"))
