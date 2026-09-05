#### RUN SAMPLE-SIZE SWEEP ####

sweep_grid <- expand_grid(
  sample_size = sample_sizes,
  iteration   = seq_len(n_iterations)
)

sweep_results <- sweep_grid |>
  pmap_dfr(function(sample_size, iteration) {
    result <- simulate_and_recover(n = sample_size, true_r = true_r)
    tibble(sample_size = sample_size, iteration = iteration) |>
      bind_cols(result)
  })

saveRDS(sweep_results, file.path(artifacts_dir, "sweep_results.rds"))
