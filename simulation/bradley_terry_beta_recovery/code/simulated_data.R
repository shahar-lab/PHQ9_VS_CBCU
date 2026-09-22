#### GENERATE TRUE PARAMETERS ####

N_subjects     <- 100
N_options      <- 15
N_trials       <- 200
mu_log_beta    <- 0.5
sigma_log_beta <- 1.5

df_true_u <- data.frame()

for (s in 1:N_subjects) {
  u_raw  <- rnorm(N_options)
  u_true <- (u_raw - mean(u_raw)) / sd(u_raw)

  df_true_u <- rbind(df_true_u, data.frame(
    subject = s,
    option  = 1:N_options,
    u_true  = u_true
  ))
}

true_beta <- rlnorm(N_subjects, meanlog = mu_log_beta, sdlog = sigma_log_beta)

df_true_beta <- data.frame(
  subject   = 1:N_subjects,
  beta_true = true_beta
)

#### SIMULATE CHOICE DATA ####

df_sim <- data.frame()

for (s in 1:N_subjects) {
  u_vec  <- df_true_u$u_true[df_true_u$subject == s]
  beta_s <- true_beta[s]

  df_sim <- rbind(df_sim, sim.block(
    subject = s,
    u       = u_vec,
    beta    = beta_s,
    cfg     = list(Noffer = N_options, Ntrials = N_trials)
  ))
}

stan_data <- list(
  N_trials    = nrow(df_sim),
  N_subjects  = N_subjects,
  N_options   = N_options,
  subject     = df_sim$subject,
  offer_A     = df_sim$offer_A,
  offer_B     = df_sim$offer_B,
  is_choice_A = as.integer(df_sim$is_choice_A)
)

saveRDS(df_sim, file.path(artifacts_dir, "simulated_data.rds"))
