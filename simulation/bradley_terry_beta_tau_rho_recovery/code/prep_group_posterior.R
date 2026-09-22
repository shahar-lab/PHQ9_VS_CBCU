#### PREP GROUP-LEVEL POSTERIOR DRAWS ####

group_vars <- c("mu_log_beta", "sigma_log_beta", "mu_tau", "sigma_tau", "mu_rho", "sigma_rho")

group_fit <- readRDS(file.path(artifacts_dir, "bt_beta_tau_rho_fit.rds"))

draws_df <- group_fit$draws(variables = group_vars) |>
  posterior::as_draws_df()

plot_df <- draws_df |>
  select(all_of(group_vars)) |>
  pivot_longer(everything(), names_to = "variable", values_to = "value") |>
  mutate(variable = factor(variable, levels = group_vars))

true_df <- group_recovery |>
  transmute(variable = factor(variable, levels = group_vars), true_value)

# Sample statistic computed directly from the individual subjects' true draws,
# a third reference point alongside the true hyperparameter and the posterior
# median: sample mean for the three mean panels, sample SD for the three SD
# panels. mu_log_beta/sigma_log_beta are on the log scale, so they compare
# against mean/sd of log(true_beta), not raw true_beta.
sample_stat_df <- tibble(
  variable    = factor(group_vars, levels = group_vars),
  sample_stat = c(
    mean(log(true_beta)),
    sd(log(true_beta)),
    mean(true_tau),
    sd(true_tau),
    mean(true_rho),
    sd(true_rho)
  )
)

# per-facet stats for the median/true annotations, since facet_wrap free scales
# means each panel needs its own summary text placed at its own top
stats_df <- plot_df |>
  group_by(variable) |>
  summarise(
    med_val = median(value),
    pd_val  = max(mean(value > 0), mean(value < 0)) * 100,
    .groups = "drop"
  ) |>
  left_join(true_df, by = "variable") |>
  left_join(sample_stat_df, by = "variable")

# pad ~20% around each facet's posterior range (plus the true value and the
# sample statistic, so neither vline is ever clipped) per the non-effect-
# posterior rule; achieved with invisible geom_blank() anchors since each
# facet has its own free x scale
xlim_posterior <- function(x, true_val, sample_stat, pad = 0.20) {
  r <- range(c(x, true_val, sample_stat)); span <- diff(r)
  c(r[1] - pad * span, r[2] + pad * span)
}

anchor_df <- plot_df |>
  left_join(true_df, by = "variable") |>
  left_join(sample_stat_df, by = "variable") |>
  group_by(variable) |>
  reframe(value = xlim_posterior(value, true_value[1], sample_stat[1]))
