#### FIT MODEL ####
# reads: artifacts/stan_data.rds · writes: artifacts/stan_fit.rds, diagnostic_summary.rds

stan_data <- readRDS(file.path(artifacts_dir, "stan_data.rds"))

model <- cmdstan_model(file.path(models_dir, fitted_model, paste0(fitted_model, ".stan")))

fit <- model$sample(
  data            = stan_data,
  chains          = n_chains,
  parallel_chains = n_chains,
  iter_warmup     = n_warmup,
  iter_sampling   = n_sampling,
  refresh         = 500
)

diagnostic_summary <- fit$diagnostic_summary()
print(diagnostic_summary)

saveRDS(diagnostic_summary, file.path(artifacts_dir, "diagnostic_summary.rds"))
fit$save_object(file.path(artifacts_dir, "stan_fit.rds"))
