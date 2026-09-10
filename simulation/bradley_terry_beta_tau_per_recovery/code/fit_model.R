#### FIT MODEL ####

model <- cmdstan_model(model_path)

fit <- model$sample(
  data            = stan_data,
  chains          = 4,
  parallel_chains = 4,
  iter_warmup     = 1000,
  iter_sampling   = 1000,
  refresh         = 500
)

fit$save_object(file.path(artifacts_dir, "bt_beta_tau_per_fit.rds"))

diagnostics <- fit$diagnostic_summary()
saveRDS(diagnostics, file.path(artifacts_dir, "diagnostic_summary.rds"))

print(diagnostics)
print(fit$summary(c(
  "mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau",
  "mu_logit_key_decay", "sigma_key_decay", "mu_rho", "sigma_rho"
)))
