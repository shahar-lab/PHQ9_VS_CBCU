#### PLOT TRUE VS ESTIMATED ####
# reads: artifacts/participant_parameters.rds
# writes: output/true vs estimated/{sigma,tau,utility}_true_vs_estimated.png
#
# One panel per session: true value (x) vs posterior median (y), identity line
# (dashed) and least-squares line (red), Pearson r. sigma is the key check: at
# high sigma choices are near-deterministic and the data barely separate sigma
# values, so the points are expected to flatten / fan out at the top.
#
# Axes cover the parameter's range (lab rule): sigma (> 0) starts at 0;
# tau and u (unbounded, 0 meaningful) are symmetric about 0.
# axis_limits() is also used by 07 and 08.

df_participant_parameters <- readRDS(file.path(artifacts_dir, "participant_parameters.rds"))

# range = "positive": [0, max + 20% of the data range]
# range = "symmetric": [-m, m], m = largest absolute value + 5%
# range = "probability": [0, 1]
axis_limits <- function(values, range) {
  switch(range,
         positive    = c(0, max(values) + 0.20 * diff(range(values))),
         symmetric   = c(-1, 1) * 1.05 * max(abs(values)),
         probability = c(0, 1))
}

# df_long has one row per point: session, true, estimated
plot_true_vs_estimated <- function(df_long, axis_label, plot_name, range) {

  limits <- axis_limits(c(df_long$true, df_long$estimated), range)

  df_r <- df_long |>
    group_by(session) |>
    summarise(pearson_r = cor(true, estimated), .groups = "drop")

  p <- ggplot(df_long, aes(x = true, y = estimated)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60") +
    geom_point(colour = "#4477AA", alpha = 0.6, size = 1.8) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_text(data = df_r, aes(x = Inf, y = -Inf, label = sprintf("[Pearson r = %.2f]", pearson_r)),
              inherit.aes = FALSE, hjust = 1.05, vjust = -0.8, size = 3.5, colour = "grey30") +
    facet_wrap(~session) +
    coord_equal(xlim = limits, ylim = limits) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = paste("True", axis_label), y = paste("Estimated", axis_label, "(posterior median)"))

  ggsave(file.path(output_true_dir, paste0(plot_name, ".png")),
         plot = p, width = 12, height = 6.5, dpi = 300, bg = "white")
  saveRDS(p, file.path(artifacts_dir, paste0("p_", plot_name, ".rds")))   # for the combined PDF

  p
}

df_sigma_true <- df_participant_parameters |>
  select(session, true = true_sigma, estimated = sigma)

df_tau_true <- df_participant_parameters |>
  select(session, true = true_tau, estimated = tau)

df_utility_true <- df_participant_parameters |>
  select(session, subject, matches("^(true_)?u_\\d+$")) |>
  pivot_longer(-c(session, subject),
               names_to = c("kind", "item"), names_pattern = "^(true_)?u_(\\d+)$") |>
  mutate(kind = if_else(kind == "true_", "true", "estimated")) |>
  pivot_wider(names_from = kind, values_from = value)

stopifnot(nrow(df_utility_true) == n_subjects * n_options * n_sessions,
          !anyNA(df_utility_true))

p_sigma_true   <- plot_true_vs_estimated(df_sigma_true, "sigma", "sigma_true_vs_estimated", "positive")
p_tau_true     <- plot_true_vs_estimated(df_tau_true, "tau (None utility)", "tau_true_vs_estimated", "symmetric")
p_utility_true <- plot_true_vs_estimated(df_utility_true, "utility (u)", "utility_true_vs_estimated", "symmetric")
