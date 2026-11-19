#### BUILD SESSION-AVERAGED UTILITY-TO-PHQ9-ITEM MAPPING TABLE ####
# Many-to-one CBCU-item -> PHQ9-item correspondence confirmed by the user. Each u-item keeps its
# own row against its mapped PHQ9 item (e.g. u_2 and u_3 are NOT averaged together, even though
# both map to phq9_2) -- only session-averaging (time1/time2 -> one value per subject) is applied.

if (!exists("df_participant_parameters")) {
  df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)
}

df_u_phq9_lookup <- tribble(
  ~u_item, ~phq9_item,
  "u_1",   "phq9_1",
  "u_2",   "phq9_2",
  "u_3",   "phq9_2",
  "u_4",   "phq9_3",
  "u_5",   "phq9_3",
  "u_6",   "phq9_4",
  "u_7",   "phq9_5",
  "u_8",   "phq9_5",
  "u_9",   "phq9_6",
  "u_10",  "phq9_6",
  "u_11",  "phq9_7",
  "u_12",  "phq9_8",
  "u_13",  "phq9_8",
  "u_14",  "phq9_9",
  "u_15",  "phq9_9"
)

# session-averaged u values, long format
df_u_session_avg <- df_participant_parameters |>
  group_by(prolific_id) |>
  summarise(across(u_1:u_15, ~ mean(.x, na.rm = TRUE)), .groups = "drop") |>
  pivot_longer(u_1:u_15, names_to = "u_item", values_to = "u_value")

# session-averaged phq9 item values, long format
df_phq9_session_avg <- df_participant_parameters |>
  group_by(prolific_id) |>
  summarise(across(phq9_1:phq9_9, ~ mean(.x, na.rm = TRUE)), .groups = "drop") |>
  pivot_longer(phq9_1:phq9_9, names_to = "phq9_item", values_to = "phq9_value")

df_utility_phq9_item_long <- df_u_session_avg |>
  left_join(df_u_phq9_lookup, by = "u_item") |>
  left_join(df_phq9_session_avg, by = c("prolific_id", "phq9_item")) |>
  select(prolific_id, u_item, phq9_item, u_value, phq9_value) |>
  drop_na(phq9_value)
