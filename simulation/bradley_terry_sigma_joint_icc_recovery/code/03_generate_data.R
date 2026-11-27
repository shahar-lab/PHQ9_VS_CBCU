#### GENERATE DATA (ONE DATASET PER RUN) ####
# reads:  artifacts/<run>/true_parameters.rds, true_u.rds
# writes: artifacts/<run>/simulated_data.rds (one row per trial), stan_data.rds

for (i in seq_along(run_names)) {
  run_dir         <- file.path(artifacts_dir, run_names[i])
  true_parameters <- readRDS(file.path(run_dir, "true_parameters.rds"))
  true_u          <- readRDS(file.path(run_dir, "true_u.rds"))

  df_simulated <- generate_bradley_terry_sigma_joint_icc(
    params    = list(units = select(true_parameters, unit, subject, session), u_all = true_u),
    n_options = n_options
  )
  stopifnot(nrow(df_simulated) == n_subjects * n_sessions * n_trials)

  stan_data <- list(
    N_trials     = nrow(df_simulated),
    N_subjects   = n_subjects,
    N_sessions   = n_sessions,
    N_units      = nrow(true_parameters),
    N_options    = n_options,
    unit_subject = true_parameters$subject,
    unit_session = true_parameters$session,
    unit_index   = df_simulated$unit_index,
    offer_A      = df_simulated$offer_A,
    offer_B      = df_simulated$offer_B,
    choice       = df_simulated$choice
  )

  # Share of None choices and of choices for the higher-utility item, as a sanity check
  df_simulated |>
    mutate(u_A = true_u[cbind(unit_index, offer_A)], u_B = true_u[cbind(unit_index, offer_B)]) |>
    summarise(p_none = mean(choice == 3),
              p_higher_item = mean((choice == 1 & u_A > u_B) | (choice == 2 & u_B > u_A)) / mean(choice != 3)) |>
    mutate(run = run_names[i], .before = 1) |>
    print()

  saveRDS(df_simulated, file.path(run_dir, "simulated_data.rds"))
  saveRDS(stan_data, file.path(run_dir, "stan_data.rds"))
}
