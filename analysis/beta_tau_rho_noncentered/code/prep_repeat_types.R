#### REPEAT TYPES: KEY (A->A, B->B) VS NEITHER (skip->skip) ####
# reads: data/processed/cbcu.csv, artifacts/participant_parameters.csv · writes: artifacts/repeat_types.csv
# One row per participant per session. Consecutive pairs are taken within block, as in
# prep_key_repeat.R. Chance rates come from the participant's own choice frequencies in
# that session: key = pA^2 + pB^2, neither = pNeither^2.

df <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  arrange(prolific_id, time, block, trial) |>
  group_by(prolific_id, time, block) |>
  mutate(previous_choice = lag(choice)) |>
  ungroup()

df_choice_freq <- df |>
  group_by(prolific_id, time) |>
  summarise(
    p_a       = mean(choice == "left"),
    p_b       = mean(choice == "right"),
    p_neither = mean(choice == "skip"),
    n_neither = sum(choice == "skip"),
    .groups   = "drop"
  )

df_rho <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE) |>
  select(prolific_id, time, rho)

df_repeat_types <- df |>
  filter(!is.na(previous_choice)) |>
  group_by(prolific_id, time) |>
  summarise(
    key_raw     = mean(choice == previous_choice & choice != "skip"),
    neither_raw = mean(choice == previous_choice & choice == "skip"),
    .groups     = "drop"
  ) |>
  left_join(df_choice_freq, by = c("prolific_id", "time")) |>
  mutate(
    key_chance     = p_a^2 + p_b^2,
    neither_chance = p_neither^2,
    key_excess     = key_raw - key_chance,
    neither_excess = neither_raw - neither_chance,
    enough_neither = n_neither >= min_neither_trials
  ) |>
  inner_join(df_rho, by = c("prolific_id", "time"))

write_csv(df_repeat_types, file.path(artifacts_dir, "repeat_types.csv"))
