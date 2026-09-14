#### RUN SAMPLE-SIZE SWEEP ####

priors <- c(
  prior(normal(0, 1), class = "Intercept"),
  prior(cauchy(0, 1), class = "sd")
)

sweep_grid <- expand_grid(
  sample_size = sample_sizes,
  iteration   = seq_len(n_iterations)
)

sweep_results <- sweep_grid |>
  pmap_dfr(function(sample_size, iteration) {
    subjects <- simulate_subjects(
      n            = sample_size,
      cbcu_icc     = cbcu_icc,
      phq9_icc     = phq9_icc,
      cbcu_n_items = cbcu_n_items,
      phq9_n_items = phq9_n_items
    )
    result <- fit_and_extract(subjects$cbcu_df, subjects$phq9_df, priors)
    tibble(sample_size = sample_size, iteration = iteration) |>
      bind_cols(result)
  })

saveRDS(sweep_results, file.path(artifacts_dir, "sweep_results.rds"))
write_csv(sweep_results, file.path(artifacts_dir, "sweep_results.csv"))

sweep_results_average <- sweep_results |>
  group_by(sample_size) |>
  summarise(
    median_diff       = mean(median_diff),
    hdi_width_85      = mean(hdi_width_85),
    hdi_width_90      = mean(hdi_width_90),
    hdi_width_95      = mean(hdi_width_95),
    mean_max_rhat     = mean(pmax(cbcu_max_rhat, phq9_max_rhat)),
    total_n_divergent = sum(cbcu_n_divergent + phq9_n_divergent)
  )

write_csv(sweep_results_average, file.path(artifacts_dir, "sweep_results_average.csv"))

# ASSUMED[no criterion given for combining two fits' rhat/divergences per replicate]:
# mean_max_rhat takes the worse (max) of the two fits' max-rhat before averaging
# across iterations, and total_n_divergent sums both fits' divergences across all
# iterations at that sample size -- a conservative, per-sample-size convergence check.
