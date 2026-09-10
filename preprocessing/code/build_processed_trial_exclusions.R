#### PARTICIPANT PHASE: KEEP ONLY INCLUDED PARTICIPANTS ####

after_participant_exclusions <- pairwise |>
  dplyr::filter(prolific_id %in% included_participants)

#### TRIAL PHASE: EACH CRITERION IN A NAMED SURVIVOR DATASET ####

after_missing  <- after_participant_exclusions |> dplyr::filter(!is.na(rt), !is.na(choice))
after_fast_rt  <- after_missing               |> dplyr::filter(rt >= rt_fast_cutoff_ms)
after_slow_rt  <- after_fast_rt               |> dplyr::filter(rt <= rt_slow_cutoff_ms)

# raw_cbcu_results_cols: authoritative column set from data/raw/cbcu_results.csv (built in
# build_cbcu_raw.R), so the processed CSV matches it exactly — dropping `pairwise`'s derived
# `subject_session` column.
raw_cbcu_results_cols <- c("prolific_id", "time", "block", "trial",
                            "item_number_left", "item_number_right",
                            "choice", "chosen_item_number", "chosen_item_text",
                            "rt", "time_elapsed", "skipped",
                            "item_phq9_left", "item_text_left",
                            "item_phq9_right", "item_text_right")

cbcu_results_processed <- after_slow_rt |>
  dplyr::select(dplyr::all_of(raw_cbcu_results_cols))

#### WRITE PROCESSED CSV ####

readr::write_csv(cbcu_results_processed, file.path(processed_dir, "cbcu_results.csv"), na = "NA")
