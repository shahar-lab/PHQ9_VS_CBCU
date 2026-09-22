#### RECOVER POSTERIOR MEANS ####

u_summary <- fit$summary("u_matrix") |>
  mutate(
    subject = as.integer(str_extract(variable, "(?<=\\[)\\d+(?=,)")),
    option  = as.integer(str_extract(variable, "(?<=,)\\d+(?=\\])"))
  ) |>
  select(subject, option, u_recovered = mean)

beta_summary <- fit$summary("beta") |>
  mutate(subject = as.integer(str_extract(variable, "\\d+"))) |>
  select(subject, beta_recovered = mean)

df_u_recovery <- df_true_u |>
  left_join(u_summary, by = c("subject", "option"))

df_beta_recovery <- df_true_beta |>
  left_join(beta_summary, by = "subject")

stopifnot(nrow(df_u_recovery) == N_subjects * N_options)
stopifnot(nrow(df_beta_recovery) == N_subjects)

saveRDS(
  list(u = df_u_recovery, beta = df_beta_recovery),
  file.path(artifacts_dir, "recovery_comparison.rds")
)

group_recovery <- fit$summary() |>
  filter(variable %in% c("mu_log_beta", "sigma_log_beta")) |>
  transmute(
    variable,
    true_value = c(mu_log_beta, sigma_log_beta)[match(
      variable, c("mu_log_beta", "sigma_log_beta")
    )],
    recovered_value = mean
  )

saveRDS(group_recovery, file.path(artifacts_dir, "group_recovery.rds"))
