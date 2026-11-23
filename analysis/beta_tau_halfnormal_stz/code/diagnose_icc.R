#### ICC MODELS: CONVERGENCE AND POSTERIOR PREDICTIVE CHECKS ####
# reads:  artifacts/brms_icc_tau_me.rds,    artifacts/tau_icc_data.csv,
#         artifacts/brms_icc_tau_plain.rds, artifacts/tau_icc_data_plain.csv,
#         artifacts/brms_icc_beta_plain.rds, artifacts/beta_icc_data_plain.csv,
#         artifacts/brms_icc_phq9.rds,       artifacts/phq9_icc_data.csv
# writes: output/diagnostic_icc_tau.pdf (tau, measurement error),
#         output/diagnostic_icc_tau_plain.pdf (tau, no measurement error),
#         output/diagnostic_icc_beta_plain.pdf (beta, no measurement error),
#         output/diagnostic_icc_phq9.pdf (PHQ-9 sum score)

icc_versions <- tibble(
  outcome   = c("tau", "tau", "beta", "phq9_sum"),
  fit_file  = c("brms_icc_tau_me.rds", "brms_icc_tau_plain.rds", "brms_icc_beta_plain.rds",
                "brms_icc_phq9.rds"),
  data_file = c("tau_icc_data.csv", "tau_icc_data_plain.csv", "beta_icc_data_plain.csv",
                "phq9_icc_data.csv"),
  pdf_file  = c("diagnostic_icc_tau.pdf", "diagnostic_icc_tau_plain.pdf",
                "diagnostic_icc_beta_plain.pdf", "diagnostic_icc_phq9.pdf")
)

# Population-level parameters only (the 185 r_id[...] draws are left out)
hyper_names <- c("b_Intercept", "sd_id__Intercept", "sigma")

for (k in seq_len(nrow(icc_versions))) {
  outcome <- icc_versions$outcome[k]
  fit_icc <- readRDS(file.path(artifacts_dir, icc_versions$fit_file[k]))
  df_icc  <- read_csv(file.path(artifacts_dir, icc_versions$data_file[k]), show_col_types = FALSE)
  y_obs   <- df_icc[[outcome]]

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

  # 2. Posterior predictive checks: point estimates, SD per day, day 1 vs day 2 correlation.
  # Rows of df_icc are in the order the model was fitted on.
  yrep <- posterior_predict(fit_icc, ndraws = 1000)

  idx_day1 <- which(df_icc$day == "time1")
  idx_day2 <- which(df_icc$day == "time2")
  idx_day2 <- idx_day2[match(df_icc$id[idx_day1], df_icc$id[idx_day2])]
  retest_r <- function(y) cor(y[idx_day1], y[idx_day2])

  ppc_density <- ppc_dens_overlay(y_obs, yrep[1:100, ]) +
    labs(title = paste("Posterior predictive:", outcome, "point estimates"))
  ppc_mean_day <- ppc_stat_grouped(y_obs, yrep, group = df_icc$day, stat = "mean") +
    labs(title = paste("Posterior predictive: mean of", outcome, "per day"))
  ppc_sd_day  <- ppc_stat_grouped(y_obs, yrep, group = df_icc$day, stat = "sd") +
    labs(title = paste("Posterior predictive: SD of", outcome, "per day"))
  ppc_retest  <- ppc_stat(y_obs, yrep, stat = retest_r) +
    labs(title = "Posterior predictive: day 1 vs day 2 correlation", x = "Pearson r")

  pdf(file.path(output_dir, icc_versions$pdf_file[k]), width = 8, height = 6)
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
