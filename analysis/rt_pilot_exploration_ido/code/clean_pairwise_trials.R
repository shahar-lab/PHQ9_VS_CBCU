#### FILTER AND SELECT PAIRWISE TRIALS ####

df_raw <- read_csv(data_path, show_col_types = FALSE)

df <- df_raw |>
  filter(phase == "pairwise") |>
  select(
    trial_index, phase_trial_num, rt,
    left_item_number, left_item_text,
    right_item_number, right_item_text,
    chosen_side, chosen_item_number, chosen_item_text,
    skipped
  ) |>
  mutate(rt = as.numeric(rt))

write_csv(df, file.path(artifacts_dir, "pairwise_trials_cleaned.csv"))
