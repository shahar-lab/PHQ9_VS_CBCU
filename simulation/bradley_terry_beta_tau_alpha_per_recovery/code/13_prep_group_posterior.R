#### PREP GROUP-LEVEL POSTERIOR DRAWS ####
# reads: artifacts/draws_pop.rds, true_population.rds, true_parameters.rds
# writes: artifacts/group_plot_data.rds

draws_pop       <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))
true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))

group_vars <- c(
  "mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau",
  "mu_logit_alpha", "sigma_alpha", "mu_rho", "sigma_rho"
)

plot_df <- draws_pop |>
  select(all_of(group_vars)) |>
  pivot_longer(everything(), names_to = "variable", values_to = "value") |>
  mutate(variable = factor(variable, levels = group_vars))

true_df <- true_population |>
  transmute(variable = factor(variable, levels = group_vars), true_value)

# Third reference point: the statistic of the drawn subjects themselves (mean for mu_*,
# SD for sigma_*), on the scale the model uses: log(beta) and logit(alpha_per).
sample_stat_df <- tibble(
  variable    = factor(group_vars, levels = group_vars),
  sample_stat = c(
    mean(log(true_parameters$beta)), sd(log(true_parameters$beta)),
    mean(true_parameters$tau),       sd(true_parameters$tau),
    mean(true_parameters$logit_alpha_per), sd(true_parameters$logit_alpha_per),
    mean(true_parameters$rho),       sd(true_parameters$rho)
  )
)

# Per-facet annotation statistics (facets have free scales)
stats_df <- plot_df |>
  group_by(variable) |>
  summarise(
    med_val = median(value),
    pd_val  = max(mean(value > 0), mean(value < 0)) * 100,
    .groups = "drop"
  ) |>
  left_join(true_df, by = "variable") |>
  left_join(sample_stat_df, by = "variable")

# Invisible anchors pad each facet's x range 20% beyond the posterior, the true value and
# the sample statistic, so no reference line is clipped
anchor_df <- plot_df |>
  left_join(true_df, by = "variable") |>
  left_join(sample_stat_df, by = "variable") |>
  group_by(variable) |>
  reframe(value = {
    r <- range(c(value, true_value, sample_stat))
    c(r[1] - 0.20 * diff(r), r[2] + 0.20 * diff(r))
  })

saveRDS(list(group_vars = group_vars, plot_df = plot_df, stats_df = stats_df, anchor_df = anchor_df),
        file.path(artifacts_dir, "group_plot_data.rds"))
