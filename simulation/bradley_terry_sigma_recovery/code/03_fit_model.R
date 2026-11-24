#### FIT MODEL (ONE PER SESSION) ####
# reads: artifacts/stan_data_list.rds
# writes: artifacts/draws_<session>.rds, diagnostic_summary_<session>.rds, hyperparameter_summary_<session>.rds
#
# The full fit is not saved: log_lik has one column per trial (21,000), which
# would make each saved fit several GB. Only the draws used downstream are kept.

stan_data_list <- readRDS(file.path(artifacts_dir, "stan_data_list.rds"))

model <- cmdstan_model(file.path(models_dir, fitted_model, paste0(fitted_model, ".stan")))

hyperparams <- c("sigma_location", "sigma_scale")

for (session in names(stan_data_list)) {

  # init = 0.5: initial values uniform(-0.5, 0.5) on the unconstrained scale,
  # as in the earlier recoveries (avoids chains starting in extreme regions)
  fit <- model$sample(
    data            = stan_data_list[[session]],
    init            = 0.5,
    chains          = n_chains,
    parallel_chains = n_chains,
    iter_warmup     = n_warmup,
    iter_sampling   = n_sampling,
    refresh         = 500
  )

  diagnostic_summary <- fit$diagnostic_summary()
  hyperparameter_summary <- fit$summary(hyperparams)

  print(session)
  print(diagnostic_summary)
  print(hyperparameter_summary)

  draws <- fit$draws(c(hyperparams, "sigma", "tau", "u_matrix"), format = "draws_matrix")

  saveRDS(draws, file.path(artifacts_dir, paste0("draws_", session, ".rds")))
  saveRDS(diagnostic_summary, file.path(artifacts_dir, paste0("diagnostic_summary_", session, ".rds")))
  saveRDS(hyperparameter_summary, file.path(artifacts_dir, paste0("hyperparameter_summary_", session, ".rds")))

  rm(fit, draws)
  gc()
}
