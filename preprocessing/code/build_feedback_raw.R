#### BUILD FEEDBACK (task-understanding text + end-of-study feedback text) ####

# Both fields arrive as separate phase-rows per participant, each holding its
# text JSON-encoded in `response`; parse then join into one row per participant+session.
task_understanding <- collected |>
  dplyr::filter(phase == "free_text_explanation") |>
  dplyr::mutate(task_understanding_text = purrr::map_chr(response, ~ jsonlite::fromJSON(.x)$explanation)) |>
  dplyr::select(prolific_pid, study_session, task_understanding_text)

feedback_text_response <- collected |>
  dplyr::filter(phase == "feedback") |>
  dplyr::mutate(feedback_text_response = purrr::map_chr(response, ~ jsonlite::fromJSON(.x)$feedback)) |>
  dplyr::select(prolific_pid, study_session, feedback_text_response)

feedback <- task_understanding |>
  dplyr::full_join(feedback_text_response, by = c("prolific_pid", "study_session"))

#### TYPE COERCION ####

feedback <- feedback |>
  dplyr::mutate(prolific_pid = factor(prolific_pid), study_session = factor(study_session, levels = study_session_levels))

readr::write_csv(feedback, file.path(raw_dir, "feedback.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

feedback_dictionary <- tibble::tribble(
  ~column,                   ~class,      ~meaning,
  "prolific_pid",            "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "study_session",           "factor",    "session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.",
  "task_understanding_text", "character", "parsed free-text task-understanding response (asked before the quiz)",
  "feedback_text_response",  "character", "parsed free-text end-of-study feedback (how the participant felt during the experiment)"
)

write_data_validation_report(feedback, feedback_dictionary, "feedback",
                              freetext_cols = c("task_understanding_text", "feedback_text_response"))
