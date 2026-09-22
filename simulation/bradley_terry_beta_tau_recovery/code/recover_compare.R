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

group_recovery <- draws_summary |>
  filter(variable %in% c("mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau")) |>
  transmute(
    variable,
    true_value = c(mu_log_beta, sigma_log_beta, mu_tau, sigma_tau)[match(
      variable, c("mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau")
    )],
    recovered_value = mean
  )

saveRDS(u_recovery, file.path(artifacts_dir, "u_recovery.rds"))
saveRDS(beta_recovery, file.path(artifacts_dir, "beta_recovery.rds"))
saveRDS(tau_recovery, file.path(artifacts_dir, "tau_recovery.rds"))
saveRDS(group_recovery, file.path(artifacts_dir, "group_recovery.rds"))
