#### DESCRIBE: ROWS AND HOUSEKEEPING ####

kept_row_ids_collected <- dplyr::bind_rows(
  collected |> dplyr::filter(phase == "pairwise" | iti_phase == "pairwise"),
  collected |> dplyr::filter(!is.na(quiz_question_num)),
  collected |> dplyr::filter(!is.na(phq9_1_score)),
  collected |> dplyr::filter(phase == "free_text_explanation"),
  collected |> dplyr::filter(phase == "feedback")
)

row_summary_collected <- tibble::tibble(
  metric = c("Rows collected", "Rows that are trial/response data",
             "Rows that are housekeeping (instructions, breaks, fullscreen prompts)",
             "Participants", "Sessions (session_1)", "Sessions (session_2)"),
  value  = c(nrow(collected),
             nrow(kept_row_ids_collected),
             nrow(collected) - nrow(kept_row_ids_collected),
             dplyr::n_distinct(collected$prolific_pid),
             dplyr::n_distinct(collected$prolific_pid[collected$study_session == "session_1"]),
             dplyr::n_distinct(collected$prolific_pid[collected$study_session == "session_2"]))
)

#### DESCRIBE: PER PARTICIPANT ####

per_participant_collected <- collected |>
  dplyr::group_by(prolific_pid, study_session) |>
  dplyr::summarise(
    n_pairwise_trials = sum(phase == "pairwise", na.rm = TRUE),
    n_quiz_questions  = sum(!is.na(quiz_question_num)),
    phq9_completed    = any(!is.na(phq9_1_score)),
    feedback_completed = any(phase == "feedback"),
    .groups = "drop"
  ) |>
  dplyr::arrange(n_pairwise_trials, n_quiz_questions, phq9_completed, feedback_completed)

#### WRITE COLLECTED-DATA STRUCTURE REPORT ####

collected_report_lines <- c(
  "# Collected data structure report", "",
  "Built by `preprocessing/code/describe_collected.R`. Describes the data exactly as it",
  "arrived in `data/collected/`, before any restructuring into `data/raw/`.", "",
  "## Rows", "", knitr::kable(row_summary_collected, format = "pipe"), "",
  "## Per participant (sorted to surface incomplete cases first)", "",
  knitr::kable(per_participant_collected, format = "pipe")
)
writeLines(collected_report_lines, file.path(output_dir, "collected-data-structure-report.md"))
