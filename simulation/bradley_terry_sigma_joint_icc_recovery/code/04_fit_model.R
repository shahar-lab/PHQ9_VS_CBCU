#### FIT MODEL (ONE JOINT FIT PER RUN) ####
# reads:  artifacts/<run>/stan_data.rds
# writes: artifacts/<run>/draws_pop.rds (population draws, incl. every ICC),
#         artifacts/<run>/draws_sbj.rds (sigma and tau draws per unit),
#         artifacts/<run>/summary_u.rds (posterior median, SD, 95% interval of every utility),
#         artifacts/<run>/diagnostics.rds (divergences, R-hat, ESS)
#
# The fit object itself is not saved: z_u, e_u and u_all add ~15,000 columns per draw (several GB).

model <- cmdstan_model(file.path(models_dir, fitted_model, paste0(fitted_model, ".stan")))

pop_variables <- c("mu_log_sigma", "s_log_sigma", "delta_log_sigma",
                   "icc_sigma", "icc_A_sigma", "icc_profile_C", "icc_profile_A", "icc_tau", "icc_A_tau",
                   "m", "delta_u")

for (i in seq_along(run_names)) {
  run_dir   <- file.path(artifacts_dir, run_names[i])
  stan_data <- readRDS(file.path(run_dir, "stan_data.rds"))

  # init = 0.5: initial values uniform(-0.5, 0.5) on the unconstrained scale, as in the sigma recovery
  fit <- model$sample(
    data            = stan_data,
    init            = 0.5,
    chains          = n_chains,
    parallel_chains = n_chains,
    iter_warmup     = n_warmup,
    iter_sampling   = n_sampling,
    refresh         = 250
  )

  draws_pop <- fit$draws(pop_variables, format = "draws_df")
  draws_sbj <- fit$draws(c("sigma", "tau"), format = "draws_matrix")
  summary_u <- fit$summary("u_all", median = median, sd = sd,
                           ~quantile(.x, probs = c(0.025, 0.975)))

  # Convergence: population parameters, and the worst unit-level parameter
  summary_pop <- summarise_draws(draws_pop, rhat = posterior::rhat,
                                 ess_bulk = posterior::ess_bulk, ess_tail = posterior::ess_tail)
  summary_sbj <- fit$summary(c("sigma", "tau", "u_all"), rhat = posterior::rhat,
                             ess_bulk = posterior::ess_bulk)
  diagnostics <- list(
    sampler     = fit$diagnostic_summary(),
    summary_pop = summary_pop,
    max_rhat_sbj     = max(summary_sbj$rhat, na.rm = TRUE),
    min_ess_bulk_sbj = min(summary_sbj$ess_bulk, na.rm = TRUE),
    time_seconds     = fit$time()$total
  )

  print(run_names[i])
  print(diagnostics$sampler)
  print(summary_pop, n = 10)

  saveRDS(draws_pop, file.path(run_dir, "draws_pop.rds"))
  saveRDS(draws_sbj, file.path(run_dir, "draws_sbj.rds"))
  saveRDS(summary_u, file.path(run_dir, "summary_u.rds"))
  saveRDS(diagnostics, file.path(run_dir, "diagnostics.rds"))

  rm(fit, draws_pop, draws_sbj, summary_u, summary_sbj)
  gc()
}
