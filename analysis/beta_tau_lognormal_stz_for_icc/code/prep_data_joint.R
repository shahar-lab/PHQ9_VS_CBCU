#### PREPARE STAN DATA FOR THE JOINT (BOTH SESSIONS) MODEL ####
# reads:  data/processed/cbcu.csv
# writes: artifacts/unit_lookup_joint.csv
#
# One Stan data list for both sessions. A "unit" is one participant in one session;
# u, beta and tau are per unit, and unit_subject links the two sessions of a participant.

df_cbcu <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE)

# Stan's categorical_logit choice coding: 1 = A (left), 2 = B (right), 3 = None (skip).
df_cbcu <- df_cbcu |>
  mutate(choice_int = case_when(
    choice == "left"  ~ 1L,
    choice == "right" ~ 2L,
    choice == "skip"  ~ 3L
  ))

sessions <- c("time1", "time2")

df_cbcu_joint <- df_cbcu |>
  filter(time %in% sessions) |>
  arrange(prolific_id, time, block, trial)

df_unit_lookup <- df_cbcu_joint |>
  distinct(prolific_id, time) |>
  arrange(prolific_id, time) |>
  mutate(unit_index    = row_number(),
         subject_index = as.integer(factor(prolific_id)),
         session_index = match(time, sessions))

write_csv(df_unit_lookup, file.path(artifacts_dir, "unit_lookup_joint.csv"))

df_cbcu_joint <- df_cbcu_joint |>
  left_join(select(df_unit_lookup, prolific_id, time, unit_index), by = c("prolific_id", "time"))

stopifnot(!anyNA(df_cbcu_joint$unit_index), !anyNA(df_cbcu_joint$choice_int))

stan_data_joint <- list(
  N_trials     = nrow(df_cbcu_joint),
  N_subjects   = n_distinct(df_unit_lookup$subject_index),
  N_sessions   = length(sessions),
  N_units      = nrow(df_unit_lookup),
  N_options    = 15,
  unit_subject = df_unit_lookup$subject_index,
  unit_session = df_unit_lookup$session_index,
  unit_index   = df_cbcu_joint$unit_index,
  offer_A      = df_cbcu_joint$item_number_left,
  offer_B      = df_cbcu_joint$item_number_right,
  choice       = df_cbcu_joint$choice_int
)
