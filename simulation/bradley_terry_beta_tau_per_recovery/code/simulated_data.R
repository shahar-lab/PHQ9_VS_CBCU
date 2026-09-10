#### GENERATE TRUE PARAMETERS ####

N_subjects <- 20
N_options  <- 15
N_trials   <- 100

# Group-level hyperparameters fixed at specific values within each prior's plausible
# range (bradley_terry_beta_tau_per.stan, model block), rather than drawn from the priors.
mu_log_beta        <- 0.5
sigma_log_beta     <- 0.3
mu_tau             <- 0
sigma_tau          <- 1
mu_logit_key_decay <- 1
sigma_key_decay    <- 0.5
mu_rho             <- 1
sigma_rho          <- 0.5

# Per-subject true utilities: raw draws standardized per subject (mean 0, sd 1),
# matching the u_matrix hard constraint in the Stan model.
true_u_raw <- matrix(rnorm(N_subjects * N_options), nrow = N_subjects, ncol = N_options)
true_u     <- matrix(t(scale(t(true_u_raw))), nrow = N_subjects, ncol = N_options)

true_beta            <- rlnorm(N_subjects, meanlog = mu_log_beta, sdlog = sigma_log_beta)
true_tau             <- rnorm(N_subjects, mean = mu_tau, sd = sigma_tau)
true_logit_key_decay <- rnorm(N_subjects, mean = mu_logit_key_decay, sd = sigma_key_decay)
true_key_decay       <- plogis(true_logit_key_decay)
true_rho             <- rnorm(N_subjects, mean = mu_rho, sd = sigma_rho)

#### SIMULATE CHOICE DATA ####

sim_list <- vector("list", N_subjects)

for (s in 1:N_subjects) {
  sim_list[[s]] <- sim.block(
    subject   = s,
    u         = true_u[s, ],
    beta      = true_beta[s],
    tau       = true_tau[s],
    key_decay = true_key_decay[s],
    rho       = true_rho[s],
    cfg       = list(Noffer = N_options, Ntrials = N_trials)
  )
}

df <- bind_rows(sim_list)

# Stan's categorical_logit needs an integer-coded choice (1 = A, 2 = B, 3 = None),
# not the "choice" factor returned by sim.block(). first_trial_in_block flags each
# subject's first trial so the Stan model's key_value running pass resets per subject.
df <- df |>
  mutate(
    choice_int = case_when(
      choice == "A"    ~ 1L,
      choice == "B"    ~ 2L,
      choice == "None" ~ 3L
    ),
    first_trial_in_block = as.integer(trial == 1)
  )

stan_data <- list(
  N_trials             = nrow(df),
  N_subjects           = N_subjects,
  N_options            = N_options,
  subject_index        = df$subject,
  offer_A              = df$offer_A,
  offer_B              = df$offer_B,
  choice               = df$choice_int,
  first_trial_in_block = df$first_trial_in_block
)

saveRDS(df, file.path(artifacts_dir, "simulated_data.rds"))
write_csv(df, file.path(artifacts_dir, "simulated_data.csv"))
