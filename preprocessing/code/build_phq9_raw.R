#### BUILD PHQ9 RESULTS ####

phq9_score_label_cols <- paste0("phq9_", 1:9, rep(c("_score", "_label"), each = 9))

phq9_results <- collected |>
  dplyr::filter(!is.na(phq9_1_score)) |>
  dplyr::select(dplyr::all_of(common_cols),
                dplyr::all_of(phq9_score_label_cols),
                attn_check_score, attn_check_label, time_to_submit_ms)

#### TYPE COERCION ####

# PHQ9's 4-point response scale, low to high severity; *_label columns (including
# attn_check_label, which uses the same scale) become an ordered factor on this scale.
phq9_response_levels <- c("Not at all", "Several days", "More than half the days", "Nearly every day")

phq9_results <- phq9_results |>
  dplyr::mutate(
    rt                 = as.numeric(ifelse(rt %in% c("NA", ""), NA, rt)),
    time_elapsed       = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed)),
    time_to_submit_ms  = as.numeric(ifelse(time_to_submit_ms %in% c("NA", ""), NA, time_to_submit_ms)),
    dplyr::across(dplyr::all_of(paste0("phq9_", 1:9, "_score")),
                  ~ as.numeric(ifelse(.x %in% c("NA", ""), NA, .x))),
    dplyr::across(dplyr::all_of(paste0("phq9_", 1:9, "_label")),
                  ~ factor(.x, levels = phq9_response_levels, ordered = TRUE)),
    attn_check_score   = as.numeric(ifelse(attn_check_score %in% c("NA", ""), NA, attn_check_score)),
    attn_check_label   = factor(attn_check_label, levels = phq9_response_levels, ordered = TRUE),
    prolific_pid       = factor(prolific_pid),
    study_session      = factor(study_session, levels = study_session_levels)
  )

readr::write_csv(phq9_results, file.path(raw_dir, "phq9_results.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

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
  "phq9_1_label...phq9_9_label", "ordered factor", "PHQ9 item response labels, items 1-9. Levels: Not at all (reference) < Several days < More than half the days < Nearly every day.",
  "attn_check_score",    "numeric",   "attention check item score",
  "attn_check_label",    "ordered factor", "attention check response label. Same levels as the phq9_*_label columns.",
  "time_to_submit_ms",   "numeric",   "time to submit the PHQ9 form, ms"
)

write_data_validation_report(phq9_results, phq9_results_dictionary, "phq9")
