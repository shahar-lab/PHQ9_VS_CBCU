#### BUILD PROCESSED PHQ9 DATA ####

phq9_item_cols <- paste0("phq9_", 1:9)

phq9_processed <- phq9_results |>
  dplyr::mutate(
    phq9_sum = rowSums(dplyr::pick(dplyr::all_of(phq9_item_cols))),
    phq9_sum = ifelse(dplyr::if_any(dplyr::all_of(phq9_item_cols), is.na), NA_real_, phq9_sum)
  ) |>
  dplyr::select(-dplyr::all_of(paste0("phq9_", 1:9, "_label")), -attn_check_label)

readr::write_csv(phq9_processed, file.path(processed_dir, "phq9_results.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

phq9_processed_dictionary <- tibble::tribble(
  ~column,               ~class,      ~meaning,
  "prolific_id",         "factor",    "Prolific participant ID (stable across sessions; the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "completion_time",     "numeric",   "time to complete the PHQ9 form, ms",
  "time",                "factor",    "time1 = first_wave, time2 = second_wave. Levels: time1 (reference), time2.",
  "phq9_1...phq9_9",     "numeric", "PHQ9 item scores, items 1-9",
  "attn_check_score",    "numeric",   "attention check item score",
  "phq9_sum",            "numeric",   "PHQ9 total score: sum of phq9_1...phq9_9, items 1-9; NA if any item is missing"
)

write_data_validation_report(phq9_processed, phq9_processed_dictionary, "phq9", suffix = "processed")
