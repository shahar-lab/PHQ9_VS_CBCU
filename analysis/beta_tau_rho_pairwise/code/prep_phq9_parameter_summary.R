#### BUILD SESSION-AVERAGED PHQ9 SUM AND PARAMETER SUMMARY ####

df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

# per-session row mean of u_1:u_15, then averaged across sessions per subject
df_phq9_parameter_summary <- df_participant_parameters |>
  rowwise() |>
  mutate(session_utility = mean(c_across(u_1:u_15), na.rm = TRUE)) |>
  ungroup() |>
  group_by(prolific_id) |>
  summarise(
    mean_utility  = mean(session_utility, na.rm = TRUE),
    mean_beta     = mean(beta, na.rm = TRUE),
    mean_tau      = mean(tau, na.rm = TRUE),
    mean_rho      = mean(rho, na.rm = TRUE),
    mean_phq9_sum = mean(phq9_sum, na.rm = TRUE),
    .groups = "drop"
  ) |>
  drop_na(mean_phq9_sum)
