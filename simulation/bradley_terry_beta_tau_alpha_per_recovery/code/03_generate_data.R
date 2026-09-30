#### GENERATE CHOICE DATA ####
# reads: artifacts/true_parameters.rds, true_u.rds
# writes: artifacts/simulated_data.rds, simulated_data.csv, stan_data.rds

true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
true_u          <- readRDS(file.path(artifacts_dir, "true_u.rds"))

sim_list <- vector("list", n_subjects)

# alpha_per is passed on the probability scale, as sim.block() reads it.
for (s in 1:n_subjects) {
  sim_list[[s]] <- sim.block(
    subject   = s,
    u         = true_u[s, ],
    beta      = true_parameters$beta[s],
    tau       = true_parameters$tau[s],
    alpha_per = true_parameters$alpha_per[s],
    rho       = true_parameters$rho[s],
    cfg       = list(Noffer = n_options, Ntrials = n_trials)
  )
}

# Stan's categorical_logit needs an integer choice (1 = A, 2 = B, 3 = None).
# first_trial_in_block flags each subject's first trial so key_value resets per subject.
df <- bind_rows(sim_list) |>
  mutate(
    choice_int = case_when(
      choice == "A"    ~ 1L,
      choice == "B"    ~ 2L,
      choice == "None" ~ 3L
    ),
    first_trial_in_block = as.integer(trial == 1)
  ) |>
  left_join(
    true_parameters |>
      select(subject, true_beta = beta, true_tau = tau, true_alpha_per = alpha_per, true_rho = rho),
    by = "subject"
  )

stan_data <- list(
  N_trials             = nrow(df),
  N_subjects           = n_subjects,
  N_options            = n_options,
  subject_index        = df$subject,
  offer_A              = df$offer_A,
  offer_B              = df$offer_B,
  choice               = df$choice_int,
  first_trial_in_block = df$first_trial_in_block
)

saveRDS(df, file.path(artifacts_dir, "simulated_data.rds"))
write_csv(df, file.path(artifacts_dir, "simulated_data.csv"))
saveRDS(stan_data, file.path(artifacts_dir, "stan_data.rds"))
