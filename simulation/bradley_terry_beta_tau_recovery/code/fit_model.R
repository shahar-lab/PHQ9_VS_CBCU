#### FIT MODEL ####

model <- cmdstan_model(model_path)

fit <- model$sample(
  data            = stan_data,
  chains          = 4,
  parallel_chains = 4,
  iter_warmup     = 3000,
  iter_sampling   = 2000,
  refresh         = 500
)

fit$save_object(file.path(artifacts_dir, "bt_beta_tau_fit.rds"))

diagnostics <- fit$diagnostic_summary()
saveRDS(diagnostics, file.path(artifacts_dir, "diagnostic_summary.rds"))

print(diagnostics)
print(fit$summary(c("mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau")))
