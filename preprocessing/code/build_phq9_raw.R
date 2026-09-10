#### BUILD PHQ9 RESULTS ####

phq9_score_label_cols <- c(paste0("phq9_", 1:9), paste0("phq9_", 1:9, "_label"))

phq9_results <- collected |>
  dplyr::filter(!is.na(phq9_1_score)) |>
  dplyr::rename_with(~ stringr::str_remove(.x, "_score$"), dplyr::matches("^phq9_[1-9]_score$")) |>
  dplyr::select(dplyr::all_of(common_cols),
                dplyr::all_of(phq9_score_label_cols),
                attn_check_score, attn_check_label) |>
  dplyr::select(-participant_id, -session) |>
  dplyr::rename(completion_time = rt)

#### TYPE COERCION ####

# PHQ9's 4-point response scale, low to high severity; *_label columns (including
# attn_check_label, which uses the same scale) become an ordered factor on this scale.
phq9_response_levels <- c("Not at all", "Several days", "More than half the days", "Nearly every day")

phq9_results <- phq9_results |>
  dplyr::mutate(
    completion_time    = as.numeric(ifelse(completion_time %in% c("NA", ""), NA, completion_time)),
    time_elapsed       = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed)),
    dplyr::across(dplyr::all_of(paste0("phq9_", 1:9)),
                  ~ as.numeric(ifelse(.x %in% c("NA", ""), NA, .x))),
    dplyr::across(dplyr::all_of(paste0("phq9_", 1:9, "_label")),
                  ~ factor(.x, levels = phq9_response_levels, ordered = TRUE)),
    attn_check_score   = as.numeric(ifelse(attn_check_score %in% c("NA", ""), NA, attn_check_score)),
    attn_check_label   = factor(attn_check_label, levels = phq9_response_levels, ordered = TRUE),
    prolific_id        = factor(prolific_id),
    time               = factor(time, levels = time_levels)
  )

readr::write_csv(phq9_results, file.path(raw_dir, "phq9_results.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

phq9_results_dictionary <- tibble::tribble(
  ~column,               ~class,      ~meaning,
  "prolific_id",         "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "completion_time",     "numeric",   "time to complete the PHQ9 form, ms",
  "time",                "factor",    "time1 = first_wave, time2 = second_wave. Levels: time1 (reference), time2.",
  "phq9_1...phq9_9",     "numeric", "PHQ9 item scores, items 1-9",
  "phq9_1_label...phq9_9_label", "ordered factor", "PHQ9 item response labels, items 1-9. Levels: Not at all (reference) < Several days < More than half the days < Nearly every day.",
  "attn_check_score",    "numeric",   "attention check item score",
  "attn_check_label",    "ordered factor", "attention check response label. Same levels as the phq9_*_label columns."
)

write_data_validation_report(phq9_results, phq9_results_dictionary, "phq9")
