#### FIT MODEL (ONE PER WAVE) ####

model <- cmdstan_model(model_path)

fit_list <- vector("list", length(waves)) |> setNames(waves)

hyperparams <- c(
  "mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau",
  "mu_logit_key_decay", "sigma_key_decay", "mu_rho", "sigma_rho"
)

for (wave in waves) {
  fit <- model$sample(
    data            = stan_data_list[[wave]],
    chains          = 4,
    parallel_chains = 4,
    iter_warmup     = 1000,
    iter_sampling   = 1000,
    refresh         = 500
  )

  fit$save_object(file.path(artifacts_dir, paste0("bt_per_fit_", wave, ".rds")))

  diagnostics <- fit$diagnostic_summary()
  saveRDS(diagnostics, file.path(artifacts_dir, paste0("diagnostic_summary_", wave, ".rds")))

  print(wave)
  print(diagnostics)
  print(fit$summary(hyperparams))

  draws         <- fit$draws(variables = hyperparams)
  summary_table <- summarise_draws(draws, ess_bulk, ess_tail, rhat)
  summary_table[-1] <- round(summary_table[-1], 2)

  trank_plot <- mcmc_rank_overlay(draws)
  pairs_plot <- mcmc_pairs(draws)

  pdf(file.path(output_dir, paste0("diagnostic_", wave, ".pdf")), width = 8, height = 6)
  grid.arrange(tableGrob(summary_table))
  print(trank_plot)
  print(pairs_plot)
  dev.off()

  fit_list[[wave]] <- fit
}
