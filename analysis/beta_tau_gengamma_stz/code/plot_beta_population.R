#### PLOT THE FITTED POPULATION OF BETA ####
# reads: fit_list (fit_model.R), df_bt_params (summarise_posterior.R),
#        prior_beta, r_truncated_normal, skewness_log_beta (prior_predictive_beta.R)
# writes: output/beta_population.png, artifacts/beta_population_summary.csv,
#         artifacts/beta_new_draws_by_wave.rds
#
# The question of this model: does the population of beta have a left tail beyond
# the lognormal?
#   A: posterior of beta_Q per wave, against its prior (grey). Mass piled up near the
#      lower bound (0.2) = the lognormal is enough; mass clearly above it = left tail.
#      If the posterior looks like the prior, the data cannot tell the shapes apart.
#   B: subject betas (posterior medians, histogram) and the fitted population
#      (posterior predictive of beta_new, line), per wave. Medians are shrunk towards
#      the population, so the histogram is a rough comparison, not a test.

population_params <- c("beta_mu", "beta_sigma", "beta_Q", "beta_new")

df_population_draws <- imap(fit_list, \(fit, wave) {
  as_draws_df(fit$draws(variables = population_params)) |>
    as_tibble() |>
    select(all_of(population_params)) |>
    mutate(time = wave)
}) |>
  list_rbind() |>
  mutate(skewness_log_beta = skewness_log_beta(beta_Q))

saveRDS(df_population_draws |> select(time, beta_new),
        file.path(artifacts_dir, "beta_new_draws_by_wave.rds"))

df_population_summary <- df_population_draws |>
  pivot_longer(c(beta_mu, beta_sigma, beta_Q, skewness_log_beta, beta_new),
               names_to = "parameter") |>
  summarise(median = median(value),
            q2.5   = quantile(value, 0.025),
            q97.5  = quantile(value, 0.975),
            .by    = c(time, parameter))
print(df_population_summary, n = Inf)
write_csv(df_population_summary, file.path(artifacts_dir, "beta_population_summary.csv"))

wave_colours <- c(time1 = "#4477AA", time2 = "#EE6677")
wave_labels  <- c(time1 = "Time 1", time2 = "Time 2")

# Panel A: posterior of Q vs prior
df_Q_prior <- tibble(
  beta_Q = r_truncated_normal(20000, prior_beta$Q_mean, prior_beta$Q_sd,
                              prior_beta$Q_lower, prior_beta$Q_upper)
)

p_beta_Q <- ggplot(df_population_draws, aes(x = beta_Q)) +
  geom_density(data = df_Q_prior, fill = "grey85", colour = NA,
               bounds = c(prior_beta$Q_lower, prior_beta$Q_upper)) +
  geom_density(aes(colour = time), linewidth = 1,
               bounds = c(prior_beta$Q_lower, prior_beta$Q_upper)) +
  scale_colour_manual(values = wave_colours, labels = wave_labels) +
  coord_cartesian(xlim = c(prior_beta$Q_lower, prior_beta$Q_upper)) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "beta_Q (lower bound 0.2 ~ lognormal)", y = "Density", colour = NULL,
       title = "Shape of the population of beta",
       subtitle = "Lines: posterior per wave. Grey: prior")

# Panel B: subject medians vs fitted population, per wave
beta_breaks <- c(0.3, 1, 3, 10, 30)
beta_range  <- range(df_bt_params$beta)

p_beta_population <- ggplot() +
  geom_histogram(data = df_bt_params, aes(x = beta, y = after_stat(density)),
                 bins = 40, fill = "grey75", colour = "white", linewidth = 0.2) +
  geom_density(data = df_population_draws, aes(x = beta_new, colour = time),
               linewidth = 1) +
  facet_wrap(~ time, ncol = 1, labeller = as_labeller(wave_labels)) +
  scale_colour_manual(values = wave_colours, labels = wave_labels, guide = "none") +
  scale_x_log10(breaks = beta_breaks, labels = as.character(beta_breaks)) +
  coord_cartesian(xlim = c(beta_range[1] / 2, beta_range[2] * 2)) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "beta (log axis)", y = "Density (per log10 unit)",
       title = "Subjects vs fitted population",
       subtitle = "Grey: subject posterior medians. Line: beta of a new subject")

p_beta_population_summary <- (p_beta_Q | p_beta_population) +
  plot_annotation(tag_levels = "A")

ggsave(file.path(output_dir, "beta_population.png"), plot = p_beta_population_summary,
       width = 14, height = 7, dpi = 300, bg = "white")
