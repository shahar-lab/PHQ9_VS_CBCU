#### BUILD FEEDBACK (task-understanding text + end-of-study feedback text) ####

# Both fields arrive as separate phase-rows per participant, each holding its
# text JSON-encoded in `response`; parse then join into one row per participant+session.
task_understanding <- collected |>
  dplyr::filter(phase == "free_text_explanation") |>
  dplyr::mutate(task_understanding_text = purrr::map_chr(response, ~ jsonlite::fromJSON(.x)$explanation)) |>
  dplyr::select(prolific_id, time, task_understanding_text)

feedback_text_response <- collected |>
  dplyr::filter(phase == "feedback") |>
  dplyr::mutate(feedback_text_response = purrr::map_chr(response, ~ jsonlite::fromJSON(.x)$feedback)) |>
  dplyr::select(prolific_id, time, feedback_text_response)

feedback <- task_understanding |>
  dplyr::full_join(feedback_text_response, by = c("prolific_id", "time"))

#### TYPE COERCION ####

feedback <- feedback |>
  dplyr::mutate(prolific_id = factor(prolific_id), time = factor(time, levels = time_levels))

readr::write_csv(feedback, file.path(raw_dir, "feedback.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

feedback_dictionary <- tibble::tribble(
  ~column,                   ~class,      ~meaning,
  "prolific_id",             "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "time",                    "factor",    "time1 = first_wave, time2 = second_wave. Levels: time1 (reference), time2.",
  "task_understanding_text", "character", "parsed free-text task-understanding response (asked before the quiz)",
  "feedback_text_response",  "character", "parsed free-text end-of-study feedback (how the participant felt during the experiment)"
)

write_data_validation_report(feedback, feedback_dictionary, "feedback",
                              freetext_cols = c("task_understanding_text", "feedback_text_response"))
