#### BUILD GROUP-MEAN UTILITY-TO-PHQ9-ITEM TABLE (15 ROWS, ACROSS ALL SUBJECTS+SESSIONS) ####
# Collapses across subjects AND sessions (unlike prep_utility_phq9_item_mapping.R, which is
# session-averaged but still one row per subject). Each of the 15 u-items gets exactly one
# group-mean value, joined to its mapped phq9-item's group-mean value via df_u_phq9_lookup.

if (!exists("df_participant_parameters")) {
  df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)
}

df_u_group_mean <- df_participant_parameters |>
  summarise(across(u_1:u_15, ~ mean(.x, na.rm = TRUE))) |>
  pivot_longer(u_1:u_15, names_to = "u_item", values_to = "u_group_mean")

df_phq9_group_mean <- df_participant_parameters |>
  summarise(across(phq9_1:phq9_9, ~ mean(.x, na.rm = TRUE))) |>
  pivot_longer(phq9_1:phq9_9, names_to = "phq9_item", values_to = "phq9_group_mean")

df_mean_utility_vs_phq9_item <- df_u_group_mean |>
  left_join(df_u_phq9_lookup, by = "u_item") |>
  left_join(df_phq9_group_mean, by = "phq9_item") |>
  select(u_item, phq9_item, u_group_mean, phq9_group_mean)
