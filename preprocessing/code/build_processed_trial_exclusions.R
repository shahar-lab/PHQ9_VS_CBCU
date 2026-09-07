#### PARTICIPANT PHASE: KEEP ONLY INCLUDED PARTICIPANTS ####

after_participant_exclusions <- pairwise |>
  dplyr::filter(prolific_pid %in% included_participants)

#### TRIAL PHASE: EACH CRITERION IN A NAMED SURVIVOR DATASET ####

after_missing  <- after_participant_exclusions |> dplyr::filter(!is.na(rt), !is.na(chosen_side))
after_fast_rt  <- after_missing               |> dplyr::filter(rt >= rt_fast_cutoff_ms)
after_slow_rt  <- after_fast_rt               |> dplyr::filter(rt <= rt_slow_cutoff_ms)

# raw_cbcu_results_cols: authoritative column set from data/raw/cbcu_results.csv (built in
# build_raw.R), so the processed CSV matches it exactly — dropping `pairwise`'s derived
# `subject_session` column and keeping `phase_trial_num` as the raw file's original character type.
raw_cbcu_results_cols <- c("participant_id", "session", "prolific_pid", "prolific_study_id",
                            "prolific_session_id", "rt", "time_elapsed", "study_session", "phase",
                            "left_item_number", "left_item_text", "right_item_number", "right_item_text",
                            "chosen_side", "chosen_item_number", "chosen_item_text",
                            "rt_from_stim_ms", "stim_onset_ms", "phase_trial_num", "skipped")

cbcu_results_processed <- after_slow_rt |>
  dplyr::mutate(phase_trial_num = as.character(phase_trial_num)) |>
  dplyr::select(dplyr::all_of(raw_cbcu_results_cols))

#### WRITE PROCESSED CSV ####

readr::write_csv(cbcu_results_processed, file.path(processed_dir, "cbcu_results.csv"), na = "NA")
