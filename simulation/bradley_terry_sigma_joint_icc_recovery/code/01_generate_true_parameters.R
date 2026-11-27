#### GENERATE TRUE PARAMETERS (ONE SET PER RUN) ####
# writes: artifacts/<run>/true_population.rds (population values, incl. true agreement ICCs),
#         artifacts/<run>/true_parameters.rds (one row per unit: sigma, tau, u_1..u_15),
#         artifacts/<run>/true_u.rds (units x 16 matrix, column 16 = None)
#
# Agreement 1 (population form): z, e ~ Normal(0, 1), combined by compose_log_sigma() and
# compose_utilities() exactly as in the .stan file.

K <- n_options + 1

units <- tibble(unit    = 1:(n_subjects * n_sessions),
                subject = rep(1:n_subjects, times = n_sessions),
                session = rep(1:n_sessions, each = n_subjects)) |>
  mutate(c = session - 1.5)

for (i in seq_along(run_names)) {
  run_dir <- file.path(artifacts_dir, run_names[i])
  dir.create(run_dir, showWarnings = FALSE)
  true_icc_sigma <- true_icc_sigma_runs[i]

  # Population values of the utilities: one ICC shared by the 15 items, one for None
  icc_u   <- c(rep(true_icc_profile_runs[i], n_options), true_icc_tau_runs[i])
  m_items <- rnorm(n_options, 0, true_m_sd)
  m       <- c(m_items - mean(m_items) - true_m_none / n_options, true_m_none)   # sums to zero
  delta_u <- rnorm(K, 0, true_delta_u_sd)
  delta_u <- delta_u - mean(delta_u)

  # Person-level standard normals
  z_sigma <- rnorm(n_subjects)
  e_sigma <- rnorm(nrow(units))
  z_u     <- matrix(rnorm(n_subjects * K), n_subjects, K)
  e_u     <- matrix(rnorm(nrow(units) * K), nrow(units), K)

  log_sigma <- compose_log_sigma(true_mu_log_sigma, true_delta_log_sigma, true_s_log_sigma,
                                 true_icc_sigma, units$c, z_sigma[units$subject], e_sigma)
  true_u    <- compose_utilities(exp(log_sigma), units$c, m, delta_u, icc_u,
                                 z_u[units$subject, ], e_u)
  stopifnot(all(abs(rowSums(true_u)) < 1e-8))

  # Agreement ICCs: the session shift counted as disagreement (McGraw & Wong ICC(A,1))
  icc_A_sigma <- true_icc_sigma * true_s_log_sigma^2 /
    (true_s_log_sigma^2 + true_delta_log_sigma^2 / 2)
  icc_profile_A <- true_icc_profile_runs[i] / (1 + mean(delta_u[1:n_options]^2) / 2)   # eq. [2]
  icc_A_tau     <- true_icc_tau_runs[i] / (1 + delta_u[K]^2 / 2)

  true_population <- tibble(
    parameter  = c("mu_log_sigma", "s_log_sigma", "delta_log_sigma",
                   "icc_sigma", "icc_A_sigma", "icc_profile_C", "icc_profile_A", "icc_tau", "icc_A_tau",
                   sprintf("m[%d]", 1:K), sprintf("delta_u[%d]", 1:K)),
    true_value = c(true_mu_log_sigma, true_s_log_sigma, true_delta_log_sigma,
                   true_icc_sigma, icc_A_sigma, true_icc_profile_runs[i], icc_profile_A,
                   true_icc_tau_runs[i], icc_A_tau, m, delta_u)
  )

  true_parameters <- units |>
    mutate(sigma = exp(log_sigma), tau = true_u[, K]) |>
    bind_cols(as_tibble(true_u[, 1:n_options], .name_repair = \(x) paste0("u_", 1:n_options)))

  saveRDS(true_population, file.path(run_dir, "true_population.rds"))
  saveRDS(true_parameters, file.path(run_dir, "true_parameters.rds"))
  saveRDS(true_u, file.path(run_dir, "true_u.rds"))
}
