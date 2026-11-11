#### GENERATE DATA ####
# reads: artifacts/true_parameters.rds, true_u.rds · writes: artifacts/simulated_data.rds, stan_data.rds

true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
true_u          <- readRDS(file.path(artifacts_dir, "true_u.rds"))

sim_list <- vector("list", n_subjects)

for (s in 1:n_subjects) {
  sim_list[[s]] <- sim.block(
    subject = s,
    u       = true_u[s, ],
    beta    = true_parameters$beta[s],
    tau     = true_parameters$tau[s],
    rho     = true_parameters$rho[s],
    cfg     = list(Noffer = n_options, Ntrials = n_trials)
  )
}

# Stan reads an integer choice (1 = A, 2 = B, 3 = None) and a flag that resets the
# perseveration carry-over on each subject's first trial
df <- bind_rows(sim_list) |>
  mutate(
    choice_int             = as.integer(choice),
    first_trial_of_subject = as.integer(trial == 1)
  )

stan_data <- list(
  N_trials               = nrow(df),
  N_subjects             = n_subjects,
  N_options              = n_options,
  subject_index          = df$subject,
  offer_A                = df$offer_A,
  offer_B                = df$offer_B,
  choice                 = df$choice_int,
  first_trial_of_subject = df$first_trial_of_subject
)

saveRDS(df, file.path(artifacts_dir, "simulated_data.rds"))
saveRDS(stan_data, file.path(artifacts_dir, "stan_data.rds"))
