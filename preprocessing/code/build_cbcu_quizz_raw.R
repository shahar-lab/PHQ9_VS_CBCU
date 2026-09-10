#### BUILD CBCU QUIZ ####

cbcu_quizz <- collected |>
  dplyr::filter(!is.na(quiz_question_num)) |>
  dplyr::select(dplyr::all_of(common_cols),
                quiz_question_num, quiz_attempt_num,
                selected_option_index, selected_option_text, correct) |>
  dplyr::select(-participant_id, -session) |>
  dplyr::rename(completion_time = rt)

#### TYPE COERCION ####

cbcu_quizz <- cbcu_quizz |>
  dplyr::mutate(
    completion_time = as.numeric(ifelse(completion_time %in% c("NA", ""), NA, completion_time)),
    time_elapsed    = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed)),
    prolific_id     = factor(prolific_id),
    time            = factor(time, levels = time_levels),
    correct         = as.logical(correct)
  )

readr::write_csv(cbcu_quizz, file.path(raw_dir, "cbcu_quizz.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

cbcu_quizz_dictionary <- tibble::tribble(
  ~column,                 ~class,      ~meaning,
  "prolific_id",           "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "completion_time",       "numeric",   "time to complete the quiz, ms",
  "time",                  "factor",    "time1 = first_wave, time2 = second_wave. Levels: time1 (reference), time2.",
  "quiz_question_num",     "character", "quiz question number, 1-6",
  "quiz_attempt_num",      "character", "attempt number for that question",
  "selected_option_index", "character", "index of selected quiz option",
  "selected_option_text",  "character", "text of selected quiz option",
  "correct",               "logical",   "whether the selection was correct"
)

write_data_validation_report(cbcu_quizz, cbcu_quizz_dictionary, "cbcu-quizz")
