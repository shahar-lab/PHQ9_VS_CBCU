#### GENERATE TRUE PARAMETERS ####

N_subjects <- 100
N_options  <- 15
N_trials   <- 105

mu_log_beta    <- 0.5
sigma_log_beta <- 1
mu_tau         <- 0
sigma_tau      <- 1

# Per-subject true utilities: raw draws standardized per subject (mean 0, sd 1),
# matching the u_matrix scale enforced in the Stan model.
true_u_raw <- matrix(rnorm(N_subjects * N_options), nrow = N_subjects, ncol = N_options)
true_u     <- matrix(t(scale(t(true_u_raw))), nrow = N_subjects, ncol = N_options)

true_beta <- rlnorm(N_subjects, meanlog = mu_log_beta, sdlog = sigma_log_beta)
true_tau  <- rnorm(N_subjects, mean = mu_tau, sd = sigma_tau)

#### SIMULATE CHOICE DATA ####

sim_list <- vector("list", N_subjects)

for (s in 1:N_subjects) {
  sim_list[[s]] <- sim.block(
    subject = s,
    u       = true_u[s, ],
    beta    = true_beta[s],
    tau     = true_tau[s],
    cfg     = list(Noffer = N_options, Ntrials = N_trials)
  )
}

df <- bind_rows(sim_list)

# Stan's categorical_logit needs an integer-coded choice (1 = A, 2 = B, 3 = None),
# not the "choice" factor returned by sim.block().
df <- df |>
  mutate(choice_int = case_when(
    choice == "A"    ~ 1L,
    choice == "B"    ~ 2L,
    choice == "None" ~ 3L
  ))

stan_data <- list(
  N_trials   = nrow(df),
  N_subjects = N_subjects,
  N_options  = N_options,
  subject    = df$subject,
  offer_A    = df$offer_A,
  offer_B    = df$offer_B,
  choice     = df$choice_int
)

saveRDS(df, file.path(artifacts_dir, "simulated_data.rds"))
