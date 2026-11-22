#### FIT MODEL (ONE FIT, BOTH SESSIONS) ####
# writes: artifacts/fit.rds, artifacts/diagnostic_summary.rds, output/diagnostic.pdf

model <- cmdstan_model(model_path)

hyperparams <- c("beta_location", "beta_scale", "tau_location", "tau_scale")

fit <- model$sample(
  data            = stan_data,
  chains          = n_chains,
  parallel_chains = n_chains,
  iter_warmup     = n_warmup,
  iter_sampling   = n_sampling,
  refresh         = 500
)

fit$save_object(file.path(artifacts_dir, "fit.rds"))

diagnostics <- fit$diagnostic_summary()
saveRDS(diagnostics, file.path(artifacts_dir, "diagnostic_summary.rds"))

print(diagnostics)
print(fit$summary(hyperparams))

draws         <- fit$draws(variables = hyperparams)
summary_table <- summarise_draws(draws, ess_bulk, ess_tail, rhat)
summary_table[-1] <- round(summary_table[-1], 2)

trank_plot <- mcmc_rank_overlay(draws)
pairs_plot <- mcmc_pairs(draws)

pdf(file.path(output_dir, "diagnostic.pdf"), width = 8, height = 6)
grid.arrange(tableGrob(summary_table))
print(trank_plot)
print(pairs_plot)
dev.off()
