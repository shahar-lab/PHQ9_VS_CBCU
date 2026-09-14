#### RUN SAMPLE-SIZE SWEEP ####

priors <- c(
  prior(normal(4, 2), class = "Intercept"),
  prior(cauchy(0, 1), class = "sd")
)

sweep_results <- sample_sizes |>
  map_dfr(function(sample_size) {
    df     <- simulate_subjects(sample_size, sigma_0, sigma_e, mean_phq9)
    result <- fit_and_extract(df, priors)
    tibble(sample_size = sample_size) |>
      bind_cols(result)
  })

saveRDS(sweep_results, file.path(artifacts_dir, "sweep_results.rds"))
write_csv(sweep_results, file.path(artifacts_dir, "sweep_results.csv"))
