#### FIT MODEL (ONE PER WAVE) ####
# reads: stan_data_list (from prep_data.R)
# writes: artifacts/fit_<wave>.rds, diagnostic_summary_<wave>.rds,
#         output/diagnostics/diagnostic_<wave>.pdf
#
# The PDF has: hyperparameter ESS/R-hat table, a count of subject-level parameters
# (sigma, tau, u) failing R-hat > 1.01 or ESS < 400, rank overlay and pairs plot of
# the hyperparameters.

model <- cmdstan_model(model_path)

fit_list <- vector("list", length(waves)) |> setNames(waves)

hyperparams <- c("sigma_location", "sigma_scale")

for (wave in waves) {
  # init = 0.5 as in the recovery simulation (avoids chains starting in extreme regions)
  fit <- model$sample(
    data            = stan_data_list[[wave]],
    init            = 0.5,
    chains          = n_chains,
    parallel_chains = n_chains,
    iter_warmup     = n_warmup,
    iter_sampling   = n_sampling,
    refresh         = 500
  )

  fit$save_object(file.path(artifacts_dir, paste0("fit_", wave, ".rds")))

  diagnostics <- fit$diagnostic_summary()
  saveRDS(diagnostics, file.path(artifacts_dir, paste0("diagnostic_summary_", wave, ".rds")))

  print(wave)
  print(diagnostics)
  print(fit$summary(hyperparams))

  draws         <- fit$draws(variables = hyperparams)
  summary_table <- summarise_draws(draws, ess_bulk, ess_tail, rhat)
  summary_table[-1] <- round(summary_table[-1], 2)

  subject_table <- fit$summary(c("sigma", "tau", "u_matrix"), rhat, ess_bulk, ess_tail) |>
    mutate(group = if_else(str_starts(variable, "u_matrix"), "u", str_extract(variable, "^[a-z]+"))) |>
    group_by(group) |>
    summarise(n_parameters      = n(),
              rhat_max          = round(max(rhat), 3),
              n_rhat_above_1.01 = sum(rhat > 1.01),
              ess_bulk_min      = round(min(ess_bulk)),
              n_ess_below_400   = sum(ess_bulk < 400 | ess_tail < 400),
              .groups = "drop")
  print(subject_table)

  trank_plot <- mcmc_rank_overlay(draws)
  pairs_plot <- mcmc_pairs(draws)

  pdf(file.path(output_diagnostics_dir, paste0("diagnostic_", wave, ".pdf")), width = 8, height = 6)
  grid.arrange(tableGrob(summary_table), top = paste(wave, "· hyperparameters"))
  grid.arrange(tableGrob(subject_table), top = paste(wave, "· subject-level parameters"))
  print(trank_plot)
  print(pairs_plot)
  dev.off()

  fit_list[[wave]] <- fit
}
