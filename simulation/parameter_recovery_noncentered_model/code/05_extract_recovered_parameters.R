#### EXTRACT RECOVERED PARAMETERS ####
# reads: artifacts/stan_fit.rds, true_population.rds, true_parameters.rds, true_u.rds, diagnostic_summary.rds
# writes: draws_pop.rds, draws_sbj.rds, recovered_parameters.rds, convergence_table.rds,
#         recovery_table.rds, population_table.rds, error_correlations.rds

fit                <- readRDS(file.path(artifacts_dir, "stan_fit.rds"))
true_population    <- readRDS(file.path(artifacts_dir, "true_population.rds"))
true_parameters    <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
true_u             <- readRDS(file.path(artifacts_dir, "true_u.rds"))
diagnostic_summary <- readRDS(file.path(artifacts_dir, "diagnostic_summary.rds"))

draws_pop <- fit$draws(true_population$stan_name, format = "draws_df")
draws_sbj <- fit$draws(c("beta", "tau", "rho", "u_matrix"), format = "draws_df")

saveRDS(draws_pop, file.path(artifacts_dir, "draws_pop.rds"))
saveRDS(draws_sbj, file.path(artifacts_dir, "draws_sbj.rds"))

#### CONVERGENCE ####

convergence_table <- bind_rows(summarise_draws(draws_pop), summarise_draws(draws_sbj)) |>
  mutate(group = case_when(
    variable %in% true_population$stan_name ~ "population",
    str_starts(variable, "u_matrix")        ~ "u",
    TRUE                                    ~ str_extract(variable, "^[a-z]+")
  )) |>
  group_by(group) |>
  summarise(rhat_max = max(rhat), ess_bulk_min = min(ess_bulk), .groups = "drop") |>
  mutate(n_divergent = sum(diagnostic_summary$num_divergent))

print(convergence_table)

#### SUBJECT-LEVEL RECOVERY ####

true_long <- bind_rows(
  expand_grid(subject = 1:n_subjects, option = 1:n_options) |>
    mutate(parameter = "u", variable = sprintf("u_matrix[%d,%d]", subject, option),
           true_value = true_u[cbind(subject, option)]),
  true_parameters |>
    pivot_longer(c(beta, tau, rho), names_to = "parameter", values_to = "true_value") |>
    mutate(variable = sprintf("%s[%d]", parameter, subject))
)

posterior_summary <- summarise_draws(draws_sbj, recovered_value = mean, posterior_sd = sd)

recovered_parameters <- true_long |>
  left_join(posterior_summary, by = "variable") |>
  mutate(parameter = factor(parameter, levels = c("u", "beta", "tau", "rho")))

recovery_table <- recovered_parameters |>
  group_by(parameter) |>
  summarise(
    pearson_r       = cor(true_value, recovered_value),
    mean_bias       = mean(recovered_value - true_value),
    slope           = coef(lm(recovered_value ~ true_value))[[2]],
    median_post_sd  = median(posterior_sd),
    true_range      = diff(range(true_value)),
    recovered_range = diff(range(recovered_value)),
    .groups = "drop"
  )

# Errors of each pair of subject-level parameters (beta, tau, rho)
error_correlations <- recovered_parameters |>
  filter(parameter != "u") |>
  mutate(error = recovered_value - true_value) |>
  select(subject, parameter, error) |>
  pivot_wider(names_from = parameter, values_from = error) |>
  select(beta, tau, rho) |>
  cor()

#### POPULATION-LEVEL RECOVERY ####

population_table <- draws_pop |>
  select(all_of(true_population$stan_name)) |>
  pivot_longer(everything(), names_to = "stan_name", values_to = "value") |>
  group_by(stan_name) |>
  summarise(median = median(value), lower_90 = quantile(value, 0.05),
            upper_90 = quantile(value, 0.95), .groups = "drop") |>
  right_join(true_population, by = "stan_name") |>
  mutate(true_in_interval = true_value >= lower_90 & true_value <= upper_90) |>
  select(parameter, true_value, median, lower_90, upper_90, true_in_interval)

print(recovery_table)
print(population_table)
print(round(error_correlations, 2))

saveRDS(recovered_parameters, file.path(artifacts_dir, "recovered_parameters.rds"))
saveRDS(convergence_table, file.path(artifacts_dir, "convergence_table.rds"))
saveRDS(recovery_table, file.path(artifacts_dir, "recovery_table.rds"))
saveRDS(population_table, file.path(artifacts_dir, "population_table.rds"))
saveRDS(error_correlations, file.path(artifacts_dir, "error_correlations.rds"))
