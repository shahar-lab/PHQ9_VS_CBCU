#### FIT MODEL ####
# reads: artifacts/stan_data.rds
# writes: artifacts/bt_beta_tau_alpha_per_fit.rds, diagnostic_summary.rds

stan_data       <- readRDS(file.path(artifacts_dir, "stan_data.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))

model <- cmdstan_model(model_path)

fit <- model$sample(
  data            = stan_data,
  chains          = n_chains,
  parallel_chains = n_chains,
  iter_warmup     = n_warmup,
  iter_sampling   = n_sampling,
  refresh         = 500
)

fit$save_object(file.path(artifacts_dir, "bt_beta_tau_alpha_per_fit.rds"))

diagnostics <- fit$diagnostic_summary()
saveRDS(diagnostics, file.path(artifacts_dir, "diagnostic_summary.rds"))

print(diagnostics)
print(fit$summary(true_population$variable))
