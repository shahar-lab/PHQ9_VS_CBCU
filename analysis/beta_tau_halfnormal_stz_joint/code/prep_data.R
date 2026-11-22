#### PREPARE STAN DATA (BOTH SESSIONS, SESSION IGNORED) ####
# reads: data/processed/cbcu.csv · writes: artifacts/subject_lookup.csv
#
# One fit for all the data: the trials of both sessions are pooled, and each subject is
# one unit (one subject_index) no matter how many sessions they completed.

df_cbcu <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE)

# Stan's categorical_logit choice coding: 1 = A (left), 2 = B (right), 3 = None (skip).
df <- df_cbcu |>
  mutate(choice_int = case_when(
    choice == "left"  ~ 1L,
    choice == "right" ~ 2L,
    choice == "skip"  ~ 3L
  )) |>
  arrange(prolific_id, time, block, trial)

subject_lookup <- df |>
  distinct(prolific_id) |>
  arrange(prolific_id) |>
  mutate(subject_index = row_number())

# No perseveration in this model, so no first_trial_of_subject flag is needed
df <- df |>
  left_join(subject_lookup, by = "prolific_id")

write_csv(subject_lookup, file.path(artifacts_dir, "subject_lookup.csv"))

print(count(df, time, name = "n_trials"))
print(summarise(count(df, prolific_id), min_trials = min(n), max_trials = max(n), n_subjects = n()))

stan_data <- list(
  N_trials      = nrow(df),
  N_subjects    = nrow(subject_lookup),
  N_options     = 15,
  subject_index = df$subject_index,
  offer_A       = df$item_number_left,
  offer_B       = df$item_number_right,
  choice        = df$choice_int
)
