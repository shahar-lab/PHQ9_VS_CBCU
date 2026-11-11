#### GENERATE TRUE PARAMETERS ####
# writes: artifacts/true_population.rds, true_parameters.rds, true_u.rds

true_population <- tibble(
  parameter  = c("mu_beta", "sigma_beta", "mu_tau", "sigma_tau", "mu_rho", "sigma_rho"),
  stan_name  = c("beta_location", "beta_scale", "tau_location", "tau_scale", "rho_location", "rho_scale"),
  true_value = c(mu_beta, sigma_beta, mu_tau, sigma_tau, mu_rho, sigma_rho)
)

# Utilities: raw draws standardized within subject (mean 0, SD 1)
true_u_raw <- matrix(rnorm(n_subjects * n_options), nrow = n_subjects, ncol = n_options)
true_u     <- t(scale(t(true_u_raw)))

# beta: normal(mu_beta, sigma_beta) truncated at 0, drawn by inverting the CDF
# on the part of the distribution above 0
lowest_cdf <- pnorm(0, mean = mu_beta, sd = sigma_beta)
true_beta  <- qnorm(runif(n_subjects, min = lowest_cdf, max = 1), mean = mu_beta, sd = sigma_beta)

true_parameters <- tibble(
  subject = 1:n_subjects,
  beta    = true_beta,
  tau     = rnorm(n_subjects, mean = mu_tau, sd = sigma_tau),
  rho     = rnorm(n_subjects, mean = mu_rho, sd = sigma_rho)
)

saveRDS(true_population, file.path(artifacts_dir, "true_population.rds"))
saveRDS(true_parameters, file.path(artifacts_dir, "true_parameters.rds"))
saveRDS(true_u, file.path(artifacts_dir, "true_u.rds"))
