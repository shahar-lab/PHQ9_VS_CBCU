#### PREPARE OBSERVED TRIALS (ONE SET OF ARRAYS PER WAVE) ####
# The simulated participant faces the same item pairs in the same order as the real one, so the
# only inputs the simulation needs are the left/right items; the observed choices are kept for the
# summary statistics of the real data.

waves <- c("time1", "time2")

# model key -> fit file prefix inside that job's artifacts folder
fit_prefix <- c(base = "bt_fit_", rho = "bt_rho_fit_", per = "bt_per_fit_")
model_labels <- c(base = "beta_tau (no perseveration)",
                  rho  = "beta_tau_rho (rho, no decay)",
                  per  = "beta_tau_per (rho + key_decay)")

# Same coding as the fitting jobs: 1 = A (left), 2 = B (right), 3 = None (skip)
df_cbcu <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  mutate(choice_int = case_when(
    choice == "left"  ~ 1L,
    choice == "right" ~ 2L,
    choice == "skip"  ~ 3L
  ))

obs_data <- map(waves, \(wave) {
  # The three jobs must list the same participants, otherwise subject indices do not line up
  lookups <- map(job_dirs, \(d) as.data.frame(read_csv(file.path(d, paste0("subject_lookup_", wave, ".csv")), show_col_types = FALSE)))
  stopifnot(isTRUE(all.equal(lookups$base, lookups$rho, check.attributes = FALSE)),
            isTRUE(all.equal(lookups$base, lookups$per, check.attributes = FALSE)))
  df_lookup <- as_tibble(lookups$base)

  # Same order as the fits: arrange(prolific_id, block, trial)
  df_wave <- df_cbcu |>
    filter(time == wave, prolific_id %in% df_lookup$prolific_id) |>
    arrange(prolific_id, block, trial) |>
    left_join(df_lookup, by = "prolific_id")

  n_subjects <- nrow(df_lookup)
  n_trials   <- nrow(df_wave) / n_subjects
  stopifnot(n_trials == 105,
            all(df_wave$subject_index == rep(seq_len(n_subjects), each = n_trials)))

  # Rows = subjects (subject_index), columns = trial position within the session
  to_matrix <- \(x) matrix(x, nrow = n_subjects, ncol = n_trials, byrow = TRUE)

  list(lookup = df_lookup,
       left   = to_matrix(df_wave$item_number_left),
       right  = to_matrix(df_wave$item_number_right),
       choice = to_matrix(df_wave$choice_int))
}) |> setNames(waves)
