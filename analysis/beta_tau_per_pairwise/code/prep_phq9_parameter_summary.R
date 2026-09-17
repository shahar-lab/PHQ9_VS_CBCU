#### BUILD SESSION-AVERAGED PHQ9 AND PARAMETER SUMMARY ####

df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

# per-session row mean of u_1:u_15, then averaged across sessions per subject
df_session_utility <- df_participant_parameters |>
  rowwise() |>
  mutate(session_utility = mean(c_across(u_1:u_15), na.rm = TRUE)) |>
  ungroup()

df_utility_beta_tau_phq9sum <- df_session_utility |>
  group_by(prolific_id) |>
  summarise(
    mean_utility  = mean(session_utility, na.rm = TRUE),
    mean_beta     = mean(beta, na.rm = TRUE),
    mean_tau      = mean(tau, na.rm = TRUE),
    mean_phq9_sum = mean(phq9_sum, na.rm = TRUE),
    .groups = "drop"
  )

# average each phq9 item across the subject's sessions first, then take the SD across the 9 averaged items
df_phq9_item_sd <- df_participant_parameters |>
  group_by(prolific_id) |>
  summarise(across(phq9_1:phq9_9, ~ mean(.x, na.rm = TRUE)), .groups = "drop") |>
  rowwise() |>
  mutate(phq9_item_sd = sd(c_across(phq9_1:phq9_9))) |>
  ungroup() |>
  select(prolific_id, phq9_item_sd)

df_phq9_parameter_summary <- df_utility_beta_tau_phq9sum |>
  left_join(df_phq9_item_sd, by = "prolific_id") |>
  drop_na(mean_phq9_sum, phq9_item_sd)
