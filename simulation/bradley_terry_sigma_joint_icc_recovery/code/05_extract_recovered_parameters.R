#### EXTRACT RECOVERED PARAMETERS ####
# reads:  artifacts/<run>/true_population.rds, true_parameters.rds, draws_pop.rds, draws_sbj.rds, summary_u.rds
# writes: artifacts/recovery_population.rds (one row per run x population parameter: true, median, 95% interval),
#         artifacts/recovered_parameters.rds (one row per run x unit x parameter: true, median, SD, 95% interval)

recovery_population  <- list()
recovered_parameters <- list()

for (i in seq_along(run_names)) {
  run_dir         <- file.path(artifacts_dir, run_names[i])
  true_population <- readRDS(file.path(run_dir, "true_population.rds"))
  true_parameters <- readRDS(file.path(run_dir, "true_parameters.rds"))
  draws_pop       <- readRDS(file.path(run_dir, "draws_pop.rds"))
  draws_sbj       <- readRDS(file.path(run_dir, "draws_sbj.rds"))
  summary_u       <- readRDS(file.path(run_dir, "summary_u.rds"))

  # Population level
  recovery_population[[i]] <- summarise_draws(draws_pop, median = median,
                                              ~quantile(.x, probs = c(0.025, 0.975))) |>
    rename(parameter = variable, lower = `2.5%`, upper = `97.5%`) |>
    inner_join(true_population, by = "parameter") |>
    mutate(run = run_names[i], covered = true_value >= lower & true_value <= upper, .before = 1)

  # Unit level: sigma and tau from their draws, utilities from the saved summary
  df_sigma_tau <- summarise_draws(draws_sbj, median = median, sd = sd,
                                  ~quantile(.x, probs = c(0.025, 0.975))) |>
    mutate(parameter = str_extract(variable, "^[a-z]+"),
           unit      = as.integer(str_extract(variable, "\\d+")))
  df_u <- summary_u |>
    mutate(unit      = as.integer(str_match(variable, "\\[(\\d+),")[, 2]),
           k         = as.integer(str_match(variable, ",(\\d+)\\]")[, 2])) |>
    filter(k <= n_options) |>
    mutate(parameter = paste0("u_", k))

  df_true <- true_parameters |>
    pivot_longer(c(sigma, tau, starts_with("u_")), names_to = "parameter", values_to = "true_value")

  recovered_parameters[[i]] <- bind_rows(df_sigma_tau, df_u) |>
    select(unit, parameter, median, sd, lower = `2.5%`, upper = `97.5%`) |>
    inner_join(df_true, by = c("unit", "parameter")) |>
    mutate(run = run_names[i], .before = 1)
}

recovery_population  <- bind_rows(recovery_population)
recovered_parameters <- bind_rows(recovered_parameters)
stopifnot(nrow(recovered_parameters) == length(run_names) * n_subjects * n_sessions * (n_options + 2))

saveRDS(recovery_population, file.path(artifacts_dir, "recovery_population.rds"))
saveRDS(recovered_parameters, file.path(artifacts_dir, "recovered_parameters.rds"))
