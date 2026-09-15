#### RUN SAMPLE-SIZE SWEEP, ONCE PER OUTCOME ####

cbcu_priors <- c(
  prior(normal(0, 1), class = "Intercept"),
  prior(cauchy(0, 1), class = "sd", group = "subject"),
  prior(cauchy(0, 1), class = "sd", group = "item")
)

phq9_priors <- c(
  prior(normal(1.5, 1), class = "Intercept"),
  prior(cauchy(0, 1), class = "sd", group = "subject"),
  prior(cauchy(0, 1), class = "sd", group = "item")
)

# Two outcomes share the same sweep-over-sample-sizes logic, only the
# generative constants and priors differ -- a custom function avoids
# duplicating the sweep body (per coding-rules.md).
run_outcome_sweep <- function(grand_mean, sigma_subject, sigma_item, sigma_e, n_items, priors) {
  sample_sizes |>
    map_dfr(function(sample_size) {
      df     <- simulate_subjects_items(sample_size, grand_mean, sigma_subject, sigma_item, sigma_e, n_items)
      result <- fit_and_extract(df, priors)
      tibble(sample_size = sample_size) |>
        bind_cols(result)
    })
}

sweep_results_cbcu <- run_outcome_sweep(
  grand_mean    = cbcu_grand_mean,
  sigma_subject = cbcu_sigma_subject,
  sigma_item    = cbcu_sigma_item,
  sigma_e       = cbcu_sigma_e,
  n_items       = cbcu_n_items,
  priors        = cbcu_priors
)

saveRDS(sweep_results_cbcu, file.path(artifacts_dir, "sweep_results_cbcu.rds"))
write_csv(sweep_results_cbcu, file.path(artifacts_dir, "sweep_results_cbcu.csv"))

sweep_results_phq9 <- run_outcome_sweep(
  grand_mean    = phq9_grand_mean,
  sigma_subject = phq9_sigma_subject,
  sigma_item    = phq9_sigma_item,
  sigma_e       = phq9_sigma_e,
  n_items       = phq9_n_items,
  priors        = phq9_priors
)

saveRDS(sweep_results_phq9, file.path(artifacts_dir, "sweep_results_phq9.rds"))
write_csv(sweep_results_phq9, file.path(artifacts_dir, "sweep_results_phq9.csv"))
