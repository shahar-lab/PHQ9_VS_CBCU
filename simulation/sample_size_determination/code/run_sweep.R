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
write_csv(sweep_results, file.path(artifacts_dir, "sweep_results.csv"))

sweep_results_average <- sweep_results |>
  group_by(sample_size) |>
  summarise(
    median_r     = mean(median_r),
    hdi_width_85 = mean(hdi_width_85),
    hdi_width_90 = mean(hdi_width_90),
    hdi_width_95 = mean(hdi_width_95)
  )

write_csv(sweep_results_average, file.path(artifacts_dir, "sweep_results_average.csv"))
