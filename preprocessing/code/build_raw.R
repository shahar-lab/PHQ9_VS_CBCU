#### CLEAN COMMON COLUMNS ####

# Values that only look like data become proper NA before any coercion.
collected <- collected |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::na_if(.x, "NA"))) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), ~ dplyr::na_if(.x, "")))

common_cols <- c("participant_id", "session", "prolific_pid", "prolific_study_id",
                  "prolific_session_id", "rt", "time_elapsed", "study_session")

#### BUILD CBCU RESULTS (pairwise trials + their iti rows) ####

cbcu_results <- collected |>
  dplyr::filter(phase == "pairwise" | iti_phase == "pairwise") |>
  dplyr::select(dplyr::all_of(common_cols), phase,
                left_item_number, left_item_text, right_item_number, right_item_text,
                chosen_side, chosen_item_number, chosen_item_text,
                rt_from_stim_ms, stim_onset_ms, phase_trial_num, skipped)

#### BUILD CBCU QUIZ ####

cbcu_quizz <- collected |>
  dplyr::filter(!is.na(quiz_question_num)) |>
  dplyr::select(dplyr::all_of(common_cols),
                quiz_question_num, quiz_attempt_num,
                selected_option_index, selected_option_text, correct)

#### BUILD PHQ9 RESULTS ####

phq9_score_label_cols <- paste0("phq9_", 1:9, rep(c("_score", "_label"), each = 9))

phq9_results <- collected |>
  dplyr::filter(!is.na(phq9_1_score)) |>
  dplyr::select(dplyr::all_of(common_cols),
                dplyr::all_of(phq9_score_label_cols),
                attn_check_score, attn_check_label, time_to_submit_ms)

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

# ASSUMED[no criterion given]: study_session coded as factor with levels
# c("session_1", "session_2"), matching prolific_pid's factor treatment.
study_session_levels <- c("session_1", "session_2")

# Named RT/timing columns per spec: rt, rt_from_stim_ms, stim_onset_ms,
# time_to_submit_ms, time_elapsed — clean "NA"/"" to NA, then coerce numeric.
cbcu_results <- cbcu_results |>
  dplyr::mutate(
    rt              = as.numeric(ifelse(rt %in% c("NA", ""), NA, rt)),
    time_elapsed    = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed)),
    rt_from_stim_ms = as.numeric(ifelse(rt_from_stim_ms %in% c("NA", ""), NA, rt_from_stim_ms)),
    stim_onset_ms   = as.numeric(ifelse(stim_onset_ms %in% c("NA", ""), NA, stim_onset_ms)),
    prolific_pid    = factor(prolific_pid),
    study_session   = factor(study_session, levels = study_session_levels)
  )

cbcu_quizz <- cbcu_quizz |>
  dplyr::mutate(
    rt              = as.numeric(ifelse(rt %in% c("NA", ""), NA, rt)),
    time_elapsed    = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed)),
    prolific_pid    = factor(prolific_pid),
    study_session   = factor(study_session, levels = study_session_levels)
  )

phq9_results <- phq9_results |>
  dplyr::mutate(
    rt                 = as.numeric(ifelse(rt %in% c("NA", ""), NA, rt)),
    time_elapsed       = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed)),
    time_to_submit_ms  = as.numeric(ifelse(time_to_submit_ms %in% c("NA", ""), NA, time_to_submit_ms)),
    dplyr::across(dplyr::all_of(paste0("phq9_", 1:9, "_score")),
                  ~ as.numeric(ifelse(.x %in% c("NA", ""), NA, .x))),
    attn_check_score   = as.numeric(ifelse(attn_check_score %in% c("NA", ""), NA, attn_check_score)),
    prolific_pid       = factor(prolific_pid),
    study_session      = factor(study_session, levels = study_session_levels)
  )

feedback <- feedback |>
  dplyr::mutate(prolific_pid = factor(prolific_pid), study_session = factor(study_session, levels = study_session_levels))

#### WRITE RAW CSVS ####

readr::write_csv(cbcu_results, file.path(raw_dir, "cbcu_results.csv"), na = "NA")
readr::write_csv(cbcu_quizz,   file.path(raw_dir, "cbcu_quizz.csv"),   na = "NA")
readr::write_csv(phq9_results, file.path(raw_dir, "phq9_results.csv"), na = "NA")
readr::write_csv(feedback,     file.path(raw_dir, "feedback.csv"),     na = "NA")

#### IDENTIFY ROWS KEPT VS. DROPPED AS HOUSEKEEPING ####

kept_row_ids <- dplyr::bind_rows(
  collected |> dplyr::filter(phase == "pairwise" | iti_phase == "pairwise"),
  collected |> dplyr::filter(!is.na(quiz_question_num)),
  collected |> dplyr::filter(!is.na(phq9_1_score)),
  collected |> dplyr::filter(phase == "free_text_explanation"),
  collected |> dplyr::filter(phase == "feedback")
)

#### DESCRIBE: PER-CSV NUMERIC AND CATEGORICAL COLUMNS ####

describe_numeric <- function(df) {
  numeric_df <- df |> dplyr::select(dplyr::where(is.numeric))
  if (ncol(numeric_df) == 0) {
    return(tibble::tibble(column = character(), n_missing = integer(),
                           min = numeric(), mean = numeric(), max = numeric()))
  }
  numeric_df |>
    tidyr::pivot_longer(dplyr::everything(), names_to = "column", values_to = "value") |>
    dplyr::group_by(column) |>
    dplyr::summarise(
      n_missing = sum(is.na(value)),
      min       = round(min(value, na.rm = TRUE), 3),
      mean      = round(mean(value, na.rm = TRUE), 3),
      max       = round(max(value, na.rm = TRUE), 3)
    )
}

describe_categorical <- function(df) {
  categorical_df <- df |> dplyr::select(dplyr::where(is.character) | dplyr::where(is.factor))
  if (ncol(categorical_df) == 0) {
    return(tibble::tibble(column = character(), n_missing = integer(),
                           n_levels = integer(), labels = character()))
  }
  categorical_df |>
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character)) |>
    tidyr::pivot_longer(dplyr::everything(), names_to = "column", values_to = "value") |>
    dplyr::group_by(column) |>
    dplyr::summarise(
      n_missing = sum(is.na(value)),
      n_levels  = dplyr::n_distinct(value, na.rm = TRUE),
      labels    = paste(head(sort(unique(value)), 6), collapse = ", ")
    )
}

cbcu_results_numeric <- describe_numeric(cbcu_results)
cbcu_results_categorical <- describe_categorical(cbcu_results)
cbcu_quizz_numeric <- describe_numeric(cbcu_quizz)
cbcu_quizz_categorical <- describe_categorical(cbcu_quizz)
phq9_results_numeric <- describe_numeric(phq9_results)
phq9_results_categorical <- describe_categorical(phq9_results)
feedback_numeric <- describe_numeric(feedback)
feedback_categorical <- describe_categorical(feedback)

#### DESCRIBE: PER-CSV DATA DICTIONARY ####

cbcu_results_dictionary <- tibble::tribble(
  ~column,               ~class,      ~meaning,
  "participant_id",      "character", "jsPsych-generated per-session code (not stable across sessions; do not use as participant key)",
  "session",             "character", "jsPsych session code",
  "prolific_pid",        "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "prolific_study_id",   "character", "Prolific study ID",
  "prolific_session_id", "character", "Prolific session ID (renamed from session_id in second_wave)",
  "rt",                  "numeric",   "jsPsych's built-in trial RT, ms (identical to rt_from_stim_ms in this task; both are timed from stimulus onset, kept as separate columns because jsPsych records rt automatically while rt_from_stim_ms is computed by the task's own code)",
  "study_session",       "factor",    "session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.",
  "phase",               "character", "\"pairwise\" for the actual comparison-response row, \"iti\" for that trial's inter-trial-interval row. iti rows have no response (chosen_side, rt, etc. are NA by design, not missing data).",
  "left_item_number",    "character", "left-side item identifier",
  "left_item_text",      "character", "left-side item text",
  "right_item_number",   "character", "right-side item identifier",
  "right_item_text",     "character", "right-side item text",
  "chosen_side",         "character", "left/right side chosen",
  "chosen_item_number",  "character", "identifier of chosen item",
  "chosen_item_text",    "character", "text of chosen item",
  "rt_from_stim_ms",     "numeric",   "RT from stimulus onset, ms (see rt above)",
  "stim_onset_ms",       "numeric",   "stimulus onset time, ms",
  "phase_trial_num",     "character", "trial number within the pairwise phase",
  "skipped",             "character", "whether the trial was skipped: \"true\" or \"false\" for pairwise response rows; blank/NA for the paired iti rows, where the field does not apply"
)

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
  "correct",               "character", "whether the selection was correct"
)

phq9_results_dictionary <- tibble::tribble(
  ~column,               ~class,      ~meaning,
  "participant_id",      "character", "jsPsych-generated per-session code (not stable across sessions; do not use as participant key)",
  "session",             "character", "jsPsych session code",
  "prolific_pid",        "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "prolific_study_id",   "character", "Prolific study ID",
  "prolific_session_id", "character", "Prolific session ID (renamed from session_id in second_wave)",
  "rt",                  "numeric",   "jsPsych's built-in RT for the PHQ9 form, ms",
  "study_session",       "factor",    "session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.",
  "phq9_1_score...phq9_9_score", "numeric", "PHQ9 item scores, items 1-9",
  "phq9_1_label...phq9_9_label", "character", "PHQ9 item response labels, items 1-9",
  "attn_check_score",    "numeric",   "attention check item score",
  "attn_check_label",    "character", "attention check response label",
  "time_to_submit_ms",   "numeric",   "time to submit the PHQ9 form, ms"
)

feedback_dictionary <- tibble::tribble(
  ~column,                   ~class,      ~meaning,
  "prolific_pid",            "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "study_session",           "factor",    "session_1 = first_wave, session_2 = second_wave. Levels: session_1 (reference), session_2.",
  "task_understanding_text", "character", "parsed free-text task-understanding response (asked before the quiz)",
  "feedback_text_response",  "character", "parsed free-text end-of-study feedback (how the participant felt during the experiment)"
)

#### WRITE RAW-DATA STRUCTURE REPORT ####

report_lines <- c(
  "# Raw data structure report", "",
  "Built by `preprocessing/code/build_raw.R`. Describes each of the four tidy CSVs written",
  "to `data/raw/` after the collected long-format event log was restructured: column names,",
  "classes, meanings, and categorical/factor coding, one section per output file.", "",

  "## cbcu_results.csv", "",
  "### Numeric columns", "", knitr::kable(cbcu_results_numeric, format = "pipe"), "",
  "### Categorical columns", "", knitr::kable(cbcu_results_categorical, format = "pipe"), "",
  "### Data dictionary", "", knitr::kable(cbcu_results_dictionary, format = "pipe"), "",

  "## cbcu_quizz.csv", "",
  "### Numeric columns", "", knitr::kable(cbcu_quizz_numeric, format = "pipe"), "",
  "### Categorical columns", "", knitr::kable(cbcu_quizz_categorical, format = "pipe"), "",
  "### Data dictionary", "", knitr::kable(cbcu_quizz_dictionary, format = "pipe"), "",

  "## phq9_results.csv", "",
  "### Numeric columns", "", knitr::kable(phq9_results_numeric, format = "pipe"), "",
  "### Categorical columns", "", knitr::kable(phq9_results_categorical, format = "pipe"), "",
  "### Data dictionary", "", knitr::kable(phq9_results_dictionary, format = "pipe"), "",

  "## feedback.csv", "",
  "### Numeric columns", "", knitr::kable(feedback_numeric, format = "pipe"), "",
  "### Categorical columns", "", knitr::kable(feedback_categorical, format = "pipe"), "",
  "### Data dictionary", "", knitr::kable(feedback_dictionary, format = "pipe")
)
writeLines(report_lines, file.path(output_dir, "raw-data-structure-report.md"))
