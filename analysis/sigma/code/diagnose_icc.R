#### ICC MODELS: CONVERGENCE AND POSTERIOR PREDICTIVE CHECKS ####
# reads:  artifacts/brms_icc_sigma_{plain,me,day_plain,day_me}.rds,
#         artifacts/sigma_icc_data_plain.csv, artifacts/sigma_icc_data.csv
# writes: output/diagnostics/diagnostic_icc_sigma_{plain,me,day_plain,day_me}.pdf
#
# Same checks as analysis/beta_tau_halfnormal_stz/code/diagnose_icc.R.

icc_versions <- tibble(
  fit_file  = c("brms_icc_sigma_plain.rds", "brms_icc_sigma_me.rds",
                "brms_icc_sigma_day_plain.rds", "brms_icc_sigma_day_me.rds"),
  data_file = c("sigma_icc_data_plain.csv", "sigma_icc_data.csv",
                "sigma_icc_data.csv", "sigma_icc_data.csv"),
  pdf_file  = c("diagnostic_icc_sigma_plain.pdf", "diagnostic_icc_sigma_me.pdf",
                "diagnostic_icc_sigma_day_plain.pdf", "diagnostic_icc_sigma_day_me.pdf")
)

for (k in seq_len(nrow(icc_versions))) {
  fit_icc <- readRDS(file.path(artifacts_dir, icc_versions$fit_file[k]))
  df_icc  <- read_csv(file.path(artifacts_dir, icc_versions$data_file[k]), show_col_types = FALSE) |>
    arrange(day, id)   # order the models were fitted on
  y_obs   <- df_icc$sigma

  # Population-level parameters only (the 185 r_id[...] draws are left out); b_daytime2 in day models
  hyper_names <- intersect(c("b_Intercept", "b_daytime2", "sd_id__Intercept", "sigma"), variables(fit_icc))

  # 1. Convergence
  draws_hyper <- as_draws_array(fit_icc, variable = hyper_names)

  # posterior:: explicitly: bayesplot and rstan (loaded by brms) mask rhat(), ess_bulk(), ess_tail()
  convergence_table <- summarise_draws(draws_hyper, median = median, sd = sd,
                                       rhat     = posterior::rhat,
                                       ess_bulk = posterior::ess_bulk,
                                       ess_tail = posterior::ess_tail)
  convergence_table[-1] <- round(convergence_table[-1], 3)

  n_divergent  <- nuts_params(fit_icc) |> filter(Parameter == "divergent__") |> pull(Value) |> sum()
  rhat_all     <- summarise_draws(as_draws_df(fit_icc), rhat = posterior::rhat)
  max_rhat_all <- max(rhat_all$rhat, na.rm = TRUE)   # includes all 185 b_0i

  print(icc_versions$fit_file[k])
  print(convergence_table)
  cat("Divergent transitions:", n_divergent, "| max R-hat over all parameters:", round(max_rhat_all, 3), "\n")

  # 2. Posterior predictive checks: point estimates, mean and SD per day, day 1 vs day 2 correlation
  yrep <- posterior_predict(fit_icc, ndraws = 1000)

  idx_day1 <- which(df_icc$day == "time1")
  idx_day2 <- which(df_icc$day == "time2")
  idx_day2 <- idx_day2[match(df_icc$id[idx_day1], df_icc$id[idx_day2])]
  retest_r <- function(y) cor(y[idx_day1], y[idx_day2])

  ppc_density <- ppc_dens_overlay(y_obs, yrep[1:100, ]) +
    labs(title = "Posterior predictive: sigma point estimates")
  ppc_mean_day <- ppc_stat_grouped(y_obs, yrep, group = df_icc$day, stat = "mean") +
    labs(title = "Posterior predictive: mean of sigma per day")
  ppc_sd_day  <- ppc_stat_grouped(y_obs, yrep, group = df_icc$day, stat = "sd") +
    labs(title = "Posterior predictive: SD of sigma per day")
  ppc_retest  <- ppc_stat(y_obs, yrep, stat = retest_r) +
    labs(title = "Posterior predictive: day 1 vs day 2 correlation", x = "Pearson r")

  pdf(file.path(output_diagnostics_dir, icc_versions$pdf_file[k]), width = 8, height = 6)
  grid.arrange(tableGrob(convergence_table),
               top = sprintf("Divergent transitions: %d | max R-hat (all parameters): %.3f",
                             n_divergent, max_rhat_all))
  print(mcmc_rank_overlay(draws_hyper))
  print(mcmc_pairs(draws_hyper))
  print(ppc_density)
  print(ppc_mean_day)
  print(ppc_sd_day)
  print(ppc_retest)
  dev.off()
}
