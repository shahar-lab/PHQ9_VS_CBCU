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
  dplyr::select(dplyr::all_of(common_cols),
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

#### DESCRIBE: ROWS AND HOUSEKEEPING ####

kept_row_ids <- dplyr::bind_rows(
  collected |> dplyr::filter(phase == "pairwise" | iti_phase == "pairwise"),
  collected |> dplyr::filter(!is.na(quiz_question_num)),
  collected |> dplyr::filter(!is.na(phq9_1_score)),
  collected |> dplyr::filter(phase == "free_text_explanation"),
  collected |> dplyr::filter(phase == "feedback")
)

row_summary <- tibble::tibble(
  metric = c("Rows kept", "Rows dropped as housekeeping", "Participants",
             "Sessions (session_1)", "Sessions (session_2)"),
  value  = c(nrow(kept_row_ids),
             nrow(collected) - nrow(kept_row_ids),
             dplyr::n_distinct(collected$prolific_pid),
             dplyr::n_distinct(collected$prolific_pid[collected$study_session == "session_1"]),
             dplyr::n_distinct(collected$prolific_pid[collected$study_session == "session_2"]))
)

#### DESCRIBE: NUMERIC AND CATEGORICAL COLUMNS ####

# Combined across the four raw outputs (id columns duplicated across outputs collapse
# to one row each via bind_rows + the per-column grouping below).
combined_raw <- dplyr::bind_rows(cbcu_results, cbcu_quizz, phq9_results, feedback)

numeric_columns <- combined_raw |>
  dplyr::select(dplyr::where(is.numeric)) |>
  tidyr::pivot_longer(dplyr::everything(), names_to = "column", values_to = "value") |>
  dplyr::group_by(column) |>
  dplyr::summarise(
    n_missing = sum(is.na(value)),
    min       = round(min(value, na.rm = TRUE), 3),
    mean      = round(mean(value, na.rm = TRUE), 3),
    max       = round(max(value, na.rm = TRUE), 3)
  )

categorical_columns <- combined_raw |>
  dplyr::select(dplyr::where(is.character) | dplyr::where(is.factor)) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), as.character)) |>
  tidyr::pivot_longer(dplyr::everything(), names_to = "column", values_to = "value") |>
  dplyr::group_by(column) |>
  dplyr::summarise(
    n_missing = sum(is.na(value)),
    n_levels  = dplyr::n_distinct(value, na.rm = TRUE),
    labels    = paste(head(sort(unique(value)), 6), collapse = ", ")
  )

#### DESCRIBE: SAMPLE OVERVIEW ####

trials_per_participant <- dplyr::count(cbcu_results |> dplyr::filter(!is.na(chosen_side)),
                                        prolific_pid, study_session, name = "n_trials")

sample_overview <- tibble::tibble(
  metric = c("Total observations (kept)", "Participants", "Sessions",
             "CBCU trials per participant (min / median / max)"),
  value  = c(format(nrow(kept_row_ids), big.mark = ","),
             format(dplyr::n_distinct(collected$prolific_pid)),
             format(dplyr::n_distinct(collected$study_session)),
             paste(min(trials_per_participant$n_trials),
                   median(trials_per_participant$n_trials),
                   max(trials_per_participant$n_trials), sep = " / "))
)

#### DESCRIBE: PER PARTICIPANT ####

per_participant <- collected |>
  dplyr::group_by(prolific_pid, study_session) |>
  dplyr::summarise(
    n_pairwise_trials = sum(phase == "pairwise", na.rm = TRUE),
    n_quiz_questions  = sum(!is.na(quiz_question_num)),
    phq9_completed    = any(!is.na(phq9_1_score)),
    feedback_completed = any(phase == "feedback"),
    .groups = "drop"
  ) |>
  dplyr::arrange(n_pairwise_trials, n_quiz_questions, phq9_completed, feedback_completed)

#### DESCRIBE: DATA DICTIONARY ####

data_dictionary <- tibble::tribble(
  ~output_csv,        ~column,                  ~class,      ~meaning,
  "cbcu_results.csv",  "participant_id",         "character", "jsPsych-generated per-session code (not stable across sessions; do not use as participant key)",
  "cbcu_results.csv",  "session",                "character", "jsPsych session code",
  "cbcu_results.csv",  "prolific_pid",           "factor",    "Prolific participant ID (stable across sessions; the participant identity key)",
  "cbcu_results.csv",  "prolific_study_id",      "character", "Prolific study ID",
  "cbcu_results.csv",  "prolific_session_id",    "character", "Prolific session ID (renamed from session_id in second_wave)",
  "cbcu_results.csv",  "rt",                     "numeric",   "general jsPsych trial RT",
  "cbcu_results.csv",  "study_session",          "factor",    "session_1 = first_wave, session_2 = second_wave",
  "cbcu_results.csv",  "left_item_number",       "character", "left-side item identifier",
  "cbcu_results.csv",  "left_item_text",         "character", "left-side item text",
  "cbcu_results.csv",  "right_item_number",      "character", "right-side item identifier",
  "cbcu_results.csv",  "right_item_text",        "character", "right-side item text",
  "cbcu_results.csv",  "chosen_side",            "character", "left/right side chosen",
  "cbcu_results.csv",  "chosen_item_number",     "character", "identifier of chosen item",
  "cbcu_results.csv",  "chosen_item_text",       "character", "text of chosen item",
  "cbcu_results.csv",  "rt_from_stim_ms",        "numeric",   "RT from stimulus onset, ms",
  "cbcu_results.csv",  "stim_onset_ms",          "numeric",   "stimulus onset time, ms",
  "cbcu_results.csv",  "phase_trial_num",        "character", "trial number within the pairwise phase",
  "cbcu_results.csv",  "skipped",                "character", "whether the trial was skipped",
  "cbcu_quizz.csv",    "quiz_question_num",      "character", "quiz question number, 1-6",
  "cbcu_quizz.csv",    "quiz_attempt_num",       "character", "attempt number for that question",
  "cbcu_quizz.csv",    "selected_option_index",  "character", "index of selected quiz option",
  "cbcu_quizz.csv",    "selected_option_text",   "character", "text of selected quiz option",
  "cbcu_quizz.csv",    "correct",                "character", "whether the selection was correct",
  "phq9_results.csv",  "phq9_1_score...phq9_9_score", "numeric", "PHQ9 item scores, items 1-9",
  "phq9_results.csv",  "phq9_1_label...phq9_9_label", "character", "PHQ9 item response labels, items 1-9",
  "phq9_results.csv",  "attn_check_score",       "numeric",   "attention check item score",
  "phq9_results.csv",  "attn_check_label",       "character", "attention check response label",
  "phq9_results.csv",  "time_to_submit_ms",      "numeric",   "time to submit the PHQ9 form, ms",
  "feedback.csv",      "task_understanding_text","character", "parsed free-text task-understanding response",
  "feedback.csv",      "feedback_text_response", "character", "parsed free-text end-of-study feedback"
)

#### WRITE REPORT ####

report_lines <- c(
  "# Collected-to-raw report", "",
  "Built by `preprocessing/code/build_raw.R`. This stage restructures the collected long-format",
  "event log into four tidy CSVs and keeps every real observation; it removes housekeeping rows",
  "(instructions, breaks, fullscreen prompts) only. This report also serves as the raw-data",
  "structure report (data dictionary, counts, categorical coding).", "",
  "## Rows", "",              knitr::kable(row_summary, format = "pipe"), "",
  "## Numeric columns", "",   knitr::kable(numeric_columns, format = "pipe"), "",
  "## Categorical columns", "", knitr::kable(categorical_columns, format = "pipe"), "",
  "## Sample overview", "",   knitr::kable(sample_overview, format = "pipe"), "",
  "## Per participant (sorted to surface incomplete cases first)", "",
  knitr::kable(per_participant, format = "pipe"), "",
  "## Data dictionary", "",
  "Factor columns: `prolific_pid` (levels = Prolific participant IDs present in the data, no fixed",
  "reference; this is the participant identity key, stable across a participant's sessions,",
  "unlike `participant_id` which jsPsych regenerates per session); `study_session`",
  "(levels `session_1`, `session_2`, reference/first level `session_1`).", "",
  knitr::kable(data_dictionary, format = "pipe")
)
writeLines(report_lines, file.path(output_dir, "collected-to-raw-report.md"))
