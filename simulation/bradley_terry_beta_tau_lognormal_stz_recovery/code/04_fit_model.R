#### FIT MODEL ####
# reads: artifacts/stan_data.rds · writes: artifacts/stan_fit.rds, diagnostic_summary.rds

stan_data <- readRDS(file.path(artifacts_dir, "stan_data.rds"))

model <- cmdstan_model(file.path(models_dir, fitted_model, paste0(fitted_model, ".stan")))

# init = 0.5: initial values are drawn uniform(-0.5, 0.5) on the unconstrained scale
# instead of Stan's default uniform(-2, 2), so chains start nearer the bulk of the
# posterior. Chains still start at different points, so R-hat stays informative.
# Background (seed 2062324528, 1000 warmup, default init): chain 1 was thrown, in its
# first ~10 warmup iterations, into a region with beta_location ~ -2, beta_scale ~ 3,
# tau_scale ~ 1e-5 and log(beta) spanning -10 to 20. It needed ~1250 iterations to
# leave it, so with 1000 warmup the step size and mass matrix were tuned there and the
# chain never mixed. Replaying the same chain with 2000 warmup recovered it.
fit <- model$sample(
  data            = stan_data,
  init            = 0.5,
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
