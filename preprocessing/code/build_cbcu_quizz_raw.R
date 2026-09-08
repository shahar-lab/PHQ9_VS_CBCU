#### BUILD CBCU QUIZ ####

cbcu_quizz <- collected |>
  dplyr::filter(!is.na(quiz_question_num)) |>
  dplyr::select(dplyr::all_of(common_cols),
                quiz_question_num, quiz_attempt_num,
                selected_option_index, selected_option_text, correct)

#### TYPE COERCION ####

cbcu_quizz <- cbcu_quizz |>
  dplyr::mutate(
    rt              = as.numeric(ifelse(rt %in% c("NA", ""), NA, rt)),
    time_elapsed    = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed)),
    prolific_pid    = factor(prolific_pid),
    study_session   = factor(study_session, levels = study_session_levels),
    correct         = as.logical(correct)
  )

readr::write_csv(cbcu_quizz, file.path(raw_dir, "cbcu_quizz.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

cbcu_quizz_dictionary <- tibble::tribble(
  ~column,                 ~class,      ~meaning,
  "participant_id",        "character", "jsPsych-generated per-session code (not stable across sessions; do not use as participant key)",
  "session",               "character", "jsPsych session code",
  "prolific_pid",          "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "prolific_study_id",     "character", "Prolific study ID",
  "prolific_session_id",   "character", "Prolific session ID (renamed from session_id in second_wave)",
  "rt",                    "numeric",   "jsPsych's built-in RT for the quiz item, ms",
  "study_session",         "factor",    "session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.",
  "quiz_question_num",     "character", "quiz question number, 1-6",
  "quiz_attempt_num",      "character", "attempt number for that question",
  "selected_option_index", "character", "index of selected quiz option",
  "selected_option_text",  "character", "text of selected quiz option",
  "correct",               "logical",   "whether the selection was correct"
)

write_data_validation_report(cbcu_quizz, cbcu_quizz_dictionary, "cbcu-quizz")
