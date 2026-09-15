#### PREPARE STAN DATA (ONE LIST PER WAVE) ####

df_cbcu <- read_csv(file.path(data_path, "cbcu_results.csv"), show_col_types = FALSE)

# Stan's categorical_logit choice coding: 1 = A (left), 2 = B (right), 3 = None (skip).
df_cbcu <- df_cbcu |>
  mutate(choice_int = case_when(
    choice == "left"  ~ 1L,
    choice == "right" ~ 2L,
    choice == "skip"  ~ 3L
  ))

# Two hierarchical fits, one per wave (see summary.md) - each wave gets its own
# subject lookup (a subject's index need not match across waves) and its own
# stan_data list, keyed by wave name.
waves          <- c("time1", "time2")
subject_lookup <- vector("list", length(waves)) |> setNames(waves)
stan_data_list <- vector("list", length(waves)) |> setNames(waves)

for (wave in waves) {
  df_wave <- df_cbcu |>
    filter(time == wave) |>
    arrange(prolific_id, block, trial)

  df_lookup <- df_wave |>
    distinct(prolific_id) |>
    arrange(prolific_id) |>
    mutate(subject_index = row_number())

  df_wave <- df_wave |>
    left_join(df_lookup, by = "prolific_id") |>
    group_by(prolific_id) |>
    mutate(first_trial_in_block = as.integer(row_number() == 1)) |>
    ungroup()

  write_csv(df_lookup, file.path(artifacts_dir, paste0("subject_lookup_", wave, ".csv")))

  subject_lookup[[wave]] <- df_lookup
  stan_data_list[[wave]] <- list(
    N_trials             = nrow(df_wave),
    N_subjects           = nrow(df_lookup),
    N_options            = 15,
    subject_index        = df_wave$subject_index,
    offer_A              = df_wave$item_number_left,
    offer_B              = df_wave$item_number_right,
    choice               = df_wave$choice_int,
    first_trial_in_block = df_wave$first_trial_in_block
  )
}
