#### HUMAN REFERENCE TRIALS ####
# reads: data/processed/cbcu.csv, artifacts/df_claude_trials.rds · writes: artifacts/df_trials.rds

df_claude <- readRDS(file.path(artifacts_dir, "df_claude_trials.rds"))

df_human_raw <- read_csv(file.path(data_path, "cbcu.csv"), col_types = cols(.default = col_character()))

# Participants get short labels (H01, H02, ...) so no Prolific ID is written to output/
df_human <- df_human_raw |>
  mutate(participant = sprintf("H%02d", dense_rank(prolific_id))) |>
  transmute(
    agent       = "Human",
    unit        = paste(participant, time, sep = "_"),
    trial       = as.integer(trial),
    left_item   = item_phq9_left,
    right_item  = item_phq9_right,
    choice      = choice,
    rt          = as.numeric(rt),
    skipped     = skipped == "TRUE"
  ) |>
  mutate(chosen_item = case_when(
    choice == "left"  ~ left_item,
    choice == "right" ~ right_item,
    .default = NA_character_
  )) |>
  arrange(unit, trial)

#### CHECKS ####

trials_per_unit <- count(df_human, unit)
stopifnot(
  all(trials_per_unit$n == n_trials_expected),
  !anyNA(df_human$rt),
  all(df_human$choice %in% c("left", "right", "skip")),
  all((df_human$choice == "skip") == df_human$skipped),
  all(df_human$left_item %in% phq9_item_order),
  all(df_human$right_item %in% phq9_item_order)
)

cat("Human participant-sessions:", n_distinct(df_human$unit), "\n")

df_trials <- bind_rows(df_claude, df_human) |>
  select(agent, unit, trial, left_item, right_item, choice, chosen_item, rt, skipped)

saveRDS(df_trials, file.path(artifacts_dir, "df_trials.rds"))
