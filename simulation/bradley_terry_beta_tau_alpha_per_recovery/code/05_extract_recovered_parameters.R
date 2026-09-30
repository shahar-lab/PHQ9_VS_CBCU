#### EXTRACT RECOVERED PARAMETERS ####
# reads: artifacts/bt_beta_tau_alpha_per_fit.rds, true_population.rds, true_parameters.rds, true_u.rds
# writes: artifacts/draws_pop.rds, draws_sbj.rds, recovered_parameters.rds

fit             <- readRDS(file.path(artifacts_dir, "bt_beta_tau_alpha_per_fit.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
true_u          <- readRDS(file.path(artifacts_dir, "true_u.rds"))

subject_vars <- c("beta", "tau", "alpha_per", "rho")

# Draws saved apart from the fit (u_matrix is summarised below rather than stored as draws:
# 3000 columns per draw)
draws_pop <- fit$draws(variables = true_population$variable, format = "draws_df")
draws_sbj <- fit$draws(variables = subject_vars, format = "draws_df")

saveRDS(draws_pop, file.path(artifacts_dir, "draws_pop.rds"))
saveRDS(draws_sbj, file.path(artifacts_dir, "draws_sbj.rds"))

# Posterior mean, SD and 90% interval (q5, q95) per subject-level value
subject_summary <- fit$summary(
  variables = c("u_matrix", subject_vars),
  mean, sd, ~quantile2(.x, probs = c(0.05, 0.95))
)

# True values in the same long layout: one row per parameter x subject (x option for u)
true_long <- bind_rows(
  true_parameters |>
    pivot_longer(all_of(subject_vars), names_to = "parameter", values_to = "true_value") |>
    select(parameter, subject, true_value) |>
    mutate(option = NA_integer_),
  tibble(
    parameter  = "u",
    subject    = rep(1:n_subjects, times = n_options),
    option     = rep(1:n_options, each = n_subjects),
    true_value = as.vector(true_u)
  )
)

index_matrix <- str_match(subject_summary$variable, "^([a-z_]+)\\[(\\d+)(?:,(\\d+))?\\]$")

recovered_parameters <- subject_summary |>
  mutate(
    parameter = str_replace(index_matrix[, 2], "^u_matrix$", "u"),
    subject   = as.integer(index_matrix[, 3]),
    option    = as.integer(index_matrix[, 4])
  ) |>
  transmute(parameter, subject, option,
            recovered_value = mean, posterior_sd = sd, q5, q95) |>
  left_join(true_long, by = c("parameter", "subject", "option"))

stopifnot(nrow(recovered_parameters) == n_subjects * (n_options + length(subject_vars)),
          !anyNA(recovered_parameters$true_value))

saveRDS(recovered_parameters, file.path(artifacts_dir, "recovered_parameters.rds"))
