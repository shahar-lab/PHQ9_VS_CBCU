#### GENERATE TRUE PARAMETERS ####
# writes: artifacts/true_population.rds, true_parameters.rds, true_u.rds

true_population <- tibble(
  parameter  = c("beta_location", "beta_scale", "tau_location", "tau_scale"),
  true_value = c(true_beta_location, true_beta_scale, true_tau_location, true_tau_scale)
)

# Utilities: drawn from the model's own prior. Each subject gets iid
# normal(0, sqrt(N / (N - 1))) draws, then is centered to sum to zero, so every
# utility has marginal SD 1, the scale tau is defined on.
u_prior_sd <- sqrt(n_options / (n_options - 1))
true_u_raw <- matrix(rnorm(n_subjects * n_options, mean = 0, sd = u_prior_sd),
                     nrow = n_subjects, ncol = n_options)
true_u     <- true_u_raw - rowMeans(true_u_raw)

# beta and tau: non-centered, as in the Stan model.
# beta_raw is a standard normal truncated below at -location / scale (so beta > 0),
# drawn by the inverse CDF.
beta_raw_lower <- -true_beta_location / true_beta_scale

true_parameters <- tibble(
  subject  = 1:n_subjects,
  beta_raw = qnorm(runif(n_subjects, min = pnorm(beta_raw_lower), max = 1)),
  tau_raw  = rnorm(n_subjects, mean = 0, sd = 1)
) |>
  mutate(
    beta = true_beta_location + true_beta_scale * beta_raw,
    tau  = true_tau_location + true_tau_scale * tau_raw
  )

stopifnot(all(true_parameters$beta > 0))

saveRDS(true_population, file.path(artifacts_dir, "true_population.rds"))
saveRDS(true_parameters, file.path(artifacts_dir, "true_parameters.rds"))
saveRDS(true_u, file.path(artifacts_dir, "true_u.rds"))
