#### DESCRIPTIVE: KEY REPEATED FROM PREVIOUS TRIAL ####
# key_repeat = 1 if the participant pressed the same key (left / right / skip) as on
# the previous trial, 0 otherwise. Computed within each participant, session, and
# block: the first trial of every block has no previous trial and gets NA.

df_key_repeat_trials <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  arrange(prolific_id, time, block, trial) |>
  group_by(prolific_id, time, block) |>
  mutate(key_repeat = as.integer(choice == lag(choice))) |>
  ungroup() |>
  select(prolific_id, time, block, trial, choice, key_repeat)

# proportion of repeated keys per participant per session (NA trials not counted)
df_key_repeat <- df_key_repeat_trials |>
  group_by(prolific_id, time) |>
  summarise(key_repeat_prop = mean(key_repeat, na.rm = TRUE), .groups = "drop")

write_csv(df_key_repeat_trials, file.path(artifacts_dir, "key_repeat_trials.csv"))
write_csv(df_key_repeat, file.path(artifacts_dir, "key_repeat_proportion.csv"))

# time1 vs time2 scatter, using plot_param_test_retest() from plot_scalar_param_test_retest.R
p_key_repeat_retest <- plot_param_test_retest(df_key_repeat, "key_repeat_prop", "proportion of repeated keys")
