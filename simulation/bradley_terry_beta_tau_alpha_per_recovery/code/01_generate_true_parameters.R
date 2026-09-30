#### GENERATE TRUE PARAMETERS ####
# reads: population values and n_subjects/n_options from main.R
# writes: artifacts/true_population.rds, true_parameters.rds, true_u.rds

true_population <- tibble(
  variable   = c("mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau",
                 "mu_logit_alpha", "sigma_alpha", "mu_rho", "sigma_rho"),
  true_value = c(mu_log_beta, sigma_log_beta, mu_tau, sigma_tau,
                 mu_logit_alpha, sigma_alpha, mu_rho, sigma_rho)
)

# Per-subject utilities: raw draws standardized per subject (mean 0, sd 1),
# matching the u_matrix constraint in the Stan model.
true_u_raw <- matrix(rnorm(n_subjects * n_options), nrow = n_subjects, ncol = n_options)
true_u     <- matrix(t(scale(t(true_u_raw))), nrow = n_subjects, ncol = n_options)

# Same population form as the Stan model: log(beta), tau, rho, logit(alpha_per) are normal.
true_parameters <- tibble(
  subject         = 1:n_subjects,
  beta            = rlnorm(n_subjects, meanlog = mu_log_beta, sdlog = sigma_log_beta),
  tau             = rnorm(n_subjects, mean = mu_tau, sd = sigma_tau),
  logit_alpha_per = rnorm(n_subjects, mean = mu_logit_alpha, sd = sigma_alpha),
  rho             = rnorm(n_subjects, mean = mu_rho, sd = sigma_rho)
) |>
  mutate(alpha_per = plogis(logit_alpha_per))

saveRDS(true_population, file.path(artifacts_dir, "true_population.rds"))
saveRDS(true_parameters, file.path(artifacts_dir, "true_parameters.rds"))
saveRDS(true_u, file.path(artifacts_dir, "true_u.rds"))
