#### ITEM-PROFILE ICC MODELS (CBCU, PHQ-9): CONVERGENCE DIAGNOSTICS ####
# reads:  artifacts/brms_icc_utility.rds, artifacts/brms_icc_phq9_items.rds
# writes: output/diagnostic_icc_utility.pdf, output/diagnostic_icc_phq9_items.pdf

icc_item_models <- c(
  "diagnostic_icc_utility.pdf"    = "brms_icc_utility.rds",
  "diagnostic_icc_phq9_items.pdf" = "brms_icc_phq9_items.rds"
)

for (pdf_file in names(icc_item_models)) {
  fit_icc <- readRDS(file.path(artifacts_dir, icc_item_models[[pdf_file]]))

  # Population-level parameters only: the intercept, the three group SDs and sigma
  # (the r_item[...], r_participant:item[...] and r_occasion:item[...] draws are left out)
  draws_full      <- as_draws_array(fit_icc)
  population_vars <- variables(draws_full)[grepl("^(b_|sd_|sigma$)", variables(draws_full))]
  draws_pop       <- subset_draws(draws_full, variable = population_vars)

  # posterior:: explicitly: bayesplot and rstan (loaded by brms) mask rhat(), ess_bulk(), ess_tail()
  convergence_table <- summarise_draws(draws_pop, median = median, sd = sd,
                                       rhat     = posterior::rhat,
                                       ess_bulk = posterior::ess_bulk,
                                       ess_tail = posterior::ess_tail)
  convergence_table[-1] <- round(convergence_table[-1], 3)

  n_divergent  <- nuts_params(fit_icc) |> filter(Parameter == "divergent__") |> pull(Value) |> sum()
  rhat_all     <- summarise_draws(as_draws_df(fit_icc), rhat = posterior::rhat)
  max_rhat_all <- max(rhat_all$rhat, na.rm = TRUE)   # includes every r_ draw

  print(icc_item_models[[pdf_file]])
  print(convergence_table)
  cat("Divergent transitions:", n_divergent, "| max R-hat over all parameters:", round(max_rhat_all, 3), "\n")

  pdf(file.path(output_dir, pdf_file), width = 10, height = 7)
  grid.arrange(tableGrob(convergence_table),
               top = sprintf("Divergent transitions: %d | max R-hat (all parameters): %.3f",
                             n_divergent, max_rhat_all))
  print(mcmc_rank_overlay(draws_pop))
  print(mcmc_pairs(draws_pop))
  dev.off()
}
