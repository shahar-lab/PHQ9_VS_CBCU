#### BUILD CBCU RESULTS (pairwise trials only) ####

# ASSUMED[no explicit block column in the raw log]: block counts how many phase2_break
# rows (break_num 1-3) occurred before each pairwise trial's jsPsych time_elapsed,
# splitting the 105 trials into blocks 1-4. Derived from the existing
# break_num/phase2_break rows. Assigned on the native jsPsych clock before
# time_elapsed is overwritten.
break_times_by_session <- collected |>
  dplyr::filter(phase == "phase2_break") |>
  dplyr::mutate(time_elapsed = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed))) |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::summarise(break_times = list(time_elapsed), .groups = "drop")

# The 15 PHQ9 sub-items in their fixed order, giving each a sequential CBCU item number 1-15.
phq9_item_order <- c("1", "2a", "2b", "3a", "3b", "4", "5a", "5b", "6a", "6b", "7", "8a", "8b", "9a", "9b")

cbcu_results <- collected |>
  dplyr::filter(phase == "pairwise") |>
  dplyr::mutate(
    time_elapsed    = as.numeric(ifelse(time_elapsed %in% c("NA", ""), NA, time_elapsed)),
    phase_trial_num = as.numeric(ifelse(phase_trial_num %in% c("NA", ""), NA, phase_trial_num)),
    rt              = as.numeric(ifelse(rt_from_stim_ms %in% c("NA", ""), NA, rt_from_stim_ms))
  ) |>
  dplyr::left_join(break_times_by_session, by = c("prolific_id", "time")) |>
  dplyr::mutate(block = 1 + purrr::map2_int(time_elapsed, break_times, ~ sum(.y < .x))) |>
  dplyr::group_by(prolific_id, time) |>
  dplyr::mutate(
    trial_onset_ms  = time_elapsed - rt,
    time_zero_ms    = trial_onset_ms[which.min(phase_trial_num)],
    time_elapsed_ms = ifelse(is.na(time_elapsed) | is.na(rt), NA_real_,
                             trial_onset_ms - time_zero_ms)
  ) |>
  dplyr::ungroup() |>
  dplyr::transmute(
    prolific_id,
    time,
    block,
    trial              = phase_trial_num,
    item_number_left   = match(left_item_number, phq9_item_order),
    item_number_right  = match(right_item_number, phq9_item_order),
    choice             = chosen_side,
    chosen_item_number = match(chosen_item_number, phq9_item_order),
    chosen_item_text,
    rt,
    time_elapsed       = time_elapsed_ms,
    skipped,
    item_phq9_left     = left_item_number,
    item_text_left     = left_item_text,
    item_phq9_right    = right_item_number,
    item_text_right    = right_item_text
  )

#### TYPE COERCION ####

cbcu_results <- cbcu_results |>
  dplyr::mutate(
    prolific_id  = factor(prolific_id),
    time         = factor(time, levels = time_levels),
    choice       = factor(choice),
    skipped      = as.logical(skipped),
    time_elapsed = hms::hms(seconds = time_elapsed / 1000)
  )

readr::write_csv(cbcu_results, file.path(raw_dir, "cbcu_results.csv"), na = "NA")

#### DESCRIBE: DATA DICTIONARY ####

cbcu_results_dictionary <- tibble::tribble(
  ~column,              ~class,      ~meaning,
  "prolific_id",        "factor",    "Prolific participant ID (the participant identity key). Levels = Prolific IDs present in the data, no fixed reference.",
  "time",               "factor",    "time1 = first_wave, time2 = second_wave. Levels: time1 (reference), time2.",
  "block",              "numeric",   "block 1-4 within the session, counted from how many of the 3 phase2_break pauses occurred before this trial",
  "trial",              "numeric",   "trial number within the pairwise phase",
  "item_number_left",   "numeric",   "left-side item's CBCU number 1-15, one per distinct PHQ9 sub-item (order: 1, 2a, 2b, 3a, 3b, 4, 5a, 5b, 6a, 6b, 7, 8a, 8b, 9a, 9b; see item_phq9_left/item_text_left at the end of the file for its PHQ9 code and text)",
  "item_number_right",  "numeric",   "right-side item's CBCU number 1-15 (see item_number_left)",
  "choice",             "factor",    "left/right side chosen, or skip. Levels: left (reference), right, skip.",
  "chosen_item_number", "numeric",   "CBCU number 1-15 of the chosen item (same numbering as item_number_left/right)",
  "chosen_item_text",   "character", "text of chosen item",
  "rt",                 "numeric",   "RT from stimulus onset, ms (renamed from rt_from_stim_ms; jsPsych's own rt column was dropped as identical)",
  "time_elapsed",       "hms",       "elapsed time from the onset of the first pairwise trial in this session (prolific_id × time), as hms. Onset = jsPsych time_elapsed − rt; time zero is the onset of the pairwise row with the smallest trial number (trial 1 when present). Trial 1 is 00:00:00. NA if this trial's jsPsych time_elapsed or rt is missing.",
  "skipped",            "logical",   "whether the trial was skipped",
  "item_phq9_left",     "character", "PHQ9 item code the left-side item was drawn from, e.g. \"2b\" (see item_number_left for its 1-15 CBCU index)",
  "item_text_left",     "character", "left-side item text",
  "item_phq9_right",    "character", "PHQ9 item code the right-side item was drawn from, e.g. \"2b\" (see item_number_right for its 1-15 CBCU index)",
  "item_text_right",    "character", "right-side item text"
)

write_data_validation_report(cbcu_results, cbcu_results_dictionary, "cbcu", step = "04")
