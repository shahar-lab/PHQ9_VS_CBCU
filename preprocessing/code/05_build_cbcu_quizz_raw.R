#### BUILD CBCU QUIZ ####

cbcu_quizz <- collected |>
  dplyr::filter(!is.na(quiz_question_num)) |>
  dplyr::select(dplyr::all_of(common_cols),
                quiz_question_num, quiz_attempt_num,
                selected_option_index, selected_option_text, correct) |>
  dplyr::select(-participant_id, -session)

#### TYPE COERCION ####

cbcu_quizz <- cbcu_quizz |>
  dplyr::mutate(
    rt           = as.numeric(ifelse(rt %in% c("NA", ""), NA, rt)),
    time_elapsed = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed)),
    prolific_id  = factor(prolific_id),
    time         = factor(time, levels = time_levels),
    correct      = as.logical(correct)
  )

# time_elapsed is jsPsych ms from experiment start until the item ended. Rebase
# per session so time zero is the onset of the first quiz item (lowest
# quiz_question_num, then lowest quiz_attempt_num). Onset = time_elapsed − rt.
# First item is 00:00:00. rt stays numeric milliseconds.
cbcu_quizz <- cbcu_quizz |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::mutate(
    q_num           = as.numeric(quiz_question_num),
    a_num           = as.numeric(quiz_attempt_num),
    item_onset_ms   = time_elapsed - rt,
    time_zero_ms    = item_onset_ms[order(q_num, a_num, na.last = TRUE)[1]],
    time_elapsed_ms = ifelse(is.na(time_elapsed) | is.na(rt), NA_real_,
                             item_onset_ms - time_zero_ms)
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(time_elapsed = hms::hms(seconds = time_elapsed_ms / 1000)) |>
  dplyr::select(-q_num, -a_num, -item_onset_ms, -time_zero_ms, -time_elapsed_ms)

readr::write_csv(cbcu_quizz, file.path(raw_dir, "cbcu_quizz.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

cbcu_quizz_dictionary <- tibble::tribble(
  ~column,                 ~class,      ~meaning,
  "prolific_id",           "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "rt",                    "numeric",   "RT from this quiz item's onset to the response, ms.",
  "time_elapsed",          "hms",       "elapsed time from the onset of the first quiz item in this session (prolific_id × time), as hms. Onset = jsPsych time_elapsed − rt; time zero is the onset of the first presentation of the first quiz item (lowest quiz_question_num, then lowest quiz_attempt_num). That item is 00:00:00. NA if this row's jsPsych time_elapsed or rt is missing.",
  "time",                  "factor",    "time1 = first_wave, time2 = second_wave. Levels: time1 (reference), time2.",
  "quiz_question_num",     "character", "quiz question number, 1-6",
  "quiz_attempt_num",      "character", "attempt number for that question",
  "selected_option_index", "character", "index of selected quiz option",
  "selected_option_text",  "character", "text of selected quiz option",
  "correct",               "logical",   "whether the selection was correct"
)

write_data_validation_report(cbcu_quizz, cbcu_quizz_dictionary, "cbcu-quizz", step = "05")
