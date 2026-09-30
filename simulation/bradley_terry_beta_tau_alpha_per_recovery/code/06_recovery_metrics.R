#### RECOVERY METRICS ####
# reads: artifacts/bt_beta_tau_alpha_per_fit.rds, diagnostic_summary.rds, draws_pop.rds,
#        recovered_parameters.rds, true_population.rds
# writes: artifacts/recovery_metrics.rds
# Numbers are reported against the criteria set in main.R; the verdict is the researcher's.

fit                  <- readRDS(file.path(artifacts_dir, "bt_beta_tau_alpha_per_fit.rds"))
diagnostics          <- readRDS(file.path(artifacts_dir, "diagnostic_summary.rds"))
draws_pop            <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))
recovered_parameters <- readRDS(file.path(artifacts_dir, "recovered_parameters.rds"))
true_population      <- readRDS(file.path(artifacts_dir, "true_population.rds"))

# 1. Convergence, before anything else
convergence <- fit$summary(
  variables = c(true_population$variable, "u_matrix", "beta", "tau", "alpha_per", "rho"),
  rhat, ess_bulk
) |>
  mutate(parameter = str_extract(variable, "^[a-z_]+")) |>
  group_by(parameter) |>
  summarise(rhat_max = max(rhat), ess_bulk_min = min(ess_bulk), .groups = "drop")

n_divergent <- sum(diagnostics$num_divergent)

# 2-4. Agent level: correlation, bias, slope, coverage, precision, shrinkage
individual_metrics <- recovered_parameters |>
  group_by(parameter) |>
  summarise(
    r                   = cor(true_value, recovered_value),
    bias                = mean(recovered_value - true_value),
    true_sd             = sd(true_value),
    bias_sd_fraction    = bias / true_sd,
    slope               = unname(coef(lm(recovered_value ~ true_value))[2]),
    coverage_90         = mean(true_value >= q5 & true_value <= q95),
    median_posterior_sd = median(posterior_sd),
    true_range          = diff(range(true_value)),
    recovered_range     = diff(range(recovered_value)),
    .groups = "drop"
  ) |>
  mutate(
    meets_r        = r >= r_min,
    meets_bias     = abs(bias_sd_fraction) <= bias_max_sd_fraction,
    meets_coverage = coverage_90 >= coverage_lo & coverage_90 <= coverage_hi
  )

# 5. Population level: posterior median and 90% interval against the true value
population_metrics <- draws_pop |>
  select(all_of(true_population$variable)) |>
  pivot_longer(everything(), names_to = "variable", values_to = "value") |>
  group_by(variable) |>
  summarise(median = median(value), q5 = quantile(value, 0.05), q95 = quantile(value, 0.95),
            .groups = "drop") |>
  left_join(true_population, by = "variable") |>
  mutate(true_inside_90 = true_value >= q5 & true_value <= q95)

# 6. Trade-offs: correlation between recovery errors of each parameter pair (u excluded)
error_correlation <- recovered_parameters |>
  filter(parameter != "u") |>
  mutate(error = recovered_value - true_value) |>
  select(parameter, subject, error) |>
  pivot_wider(names_from = parameter, values_from = error) |>
  select(-subject) |>
  cor()

recovery_metrics <- list(
  convergence = convergence, n_divergent = n_divergent,
  individual = individual_metrics, population = population_metrics,
  error_correlation = error_correlation
)
saveRDS(recovery_metrics, file.path(artifacts_dir, "recovery_metrics.rds"))

print(convergence)
cat("Divergent transitions:", n_divergent, "\n")
print(individual_metrics, width = Inf)
print(population_metrics)
print(round(error_correlation, 2))
