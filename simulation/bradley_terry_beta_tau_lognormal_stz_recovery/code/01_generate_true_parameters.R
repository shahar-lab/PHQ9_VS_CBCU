#### GENERATE TRUE PARAMETERS ####
# writes: artifacts/true_population.rds, true_parameters.rds, true_u.rds

# parameter = name used in main.R; stan_name = name in the .stan file
true_population <- tibble(
  parameter  = c("beta_location", "beta_scale", "tau_location", "tau_scale"),
  stan_name  = c("beta_location", "beta_scale", "tau_location", "tau_scale"),
  true_value = c(true_beta_location, true_beta_scale, true_tau_location, true_tau_scale)
)

# Utilities: drawn from the model's own prior. Each subject gets iid
# normal(0, sqrt(N / (N - 1))) draws, then is centered to sum to zero. Centering
# shrinks each value's marginal SD by sqrt((N - 1) / N), so every utility ends up
# with marginal SD 1, the scale tau is defined on.
u_prior_sd <- sqrt(n_options / (n_options - 1))
true_u_raw <- matrix(rnorm(n_subjects * n_options, mean = 0, sd = u_prior_sd),
                     nrow = n_subjects, ncol = n_options)
true_u     <- true_u_raw - rowMeans(true_u_raw)

# beta and tau: non-centered, as in the Stan model
true_parameters <- tibble(
  subject  = 1:n_subjects,
  beta_raw = rnorm(n_subjects, mean = 0, sd = 1),
  tau_raw  = rnorm(n_subjects, mean = 0, sd = 1)
) |>
  mutate(
    beta = exp(true_beta_location + true_beta_scale * beta_raw),
    tau  = true_tau_location + true_tau_scale * tau_raw
  )

saveRDS(true_population, file.path(artifacts_dir, "true_population.rds"))
saveRDS(true_parameters, file.path(artifacts_dir, "true_parameters.rds"))
saveRDS(true_u, file.path(artifacts_dir, "true_u.rds"))
