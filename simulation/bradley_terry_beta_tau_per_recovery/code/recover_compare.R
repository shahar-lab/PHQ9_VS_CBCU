#### RECOVER PARAMETERS ####

draws_summary <- fit$summary()

u_recovery <- draws_summary |>
  filter(str_detect(variable, "^u_matrix\\[")) |>
  mutate(
    subject = as.integer(str_match(variable, "u_matrix\\[(\\d+),(\\d+)\\]")[, 2]),
    option  = as.integer(str_match(variable, "u_matrix\\[(\\d+),(\\d+)\\]")[, 3])
  ) |>
  transmute(subject, option,
            true_value      = true_u[cbind(subject, option)],
            recovered_value = mean)

beta_recovery <- draws_summary |>
  filter(str_detect(variable, "^beta\\[")) |>
  mutate(subject = as.integer(str_match(variable, "beta\\[(\\d+)\\]")[, 2])) |>
  transmute(subject,
            true_value      = true_beta[subject],
            recovered_value = mean)

tau_recovery <- draws_summary |>
  filter(str_detect(variable, "^tau\\[")) |>
  mutate(subject = as.integer(str_match(variable, "tau\\[(\\d+)\\]")[, 2])) |>
  transmute(subject,
            true_value      = true_tau[subject],
            recovered_value = mean)

key_decay_recovery <- draws_summary |>
  filter(str_detect(variable, "^key_decay\\[")) |>
  mutate(subject = as.integer(str_match(variable, "key_decay\\[(\\d+)\\]")[, 2])) |>
  transmute(subject,
            true_value      = true_key_decay[subject],
            recovered_value = mean)

rho_recovery <- draws_summary |>
  filter(str_detect(variable, "^rho\\[")) |>
  mutate(subject = as.integer(str_match(variable, "rho\\[(\\d+)\\]")[, 2])) |>
  transmute(subject,
            true_value      = true_rho[subject],
            recovered_value = mean)

group_recovery <- draws_summary |>
  filter(variable %in% c(
    "mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau",
    "mu_logit_key_decay", "sigma_key_decay", "mu_rho", "sigma_rho"
  )) |>
  transmute(
    variable,
    true_value = c(
      mu_log_beta, sigma_log_beta, mu_tau, sigma_tau,
      mu_logit_key_decay, sigma_key_decay, mu_rho, sigma_rho
    )[match(variable, c(
      "mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau",
      "mu_logit_key_decay", "sigma_key_decay", "mu_rho", "sigma_rho"
    ))],
    recovered_value = mean
  )

saveRDS(u_recovery, file.path(artifacts_dir, "u_recovery.rds"))
saveRDS(beta_recovery, file.path(artifacts_dir, "beta_recovery.rds"))
saveRDS(tau_recovery, file.path(artifacts_dir, "tau_recovery.rds"))
saveRDS(key_decay_recovery, file.path(artifacts_dir, "key_decay_recovery.rds"))
saveRDS(rho_recovery, file.path(artifacts_dir, "rho_recovery.rds"))
saveRDS(group_recovery, file.path(artifacts_dir, "group_recovery.rds"))
