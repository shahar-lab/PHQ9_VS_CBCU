#### PLOT PARAMETER TEST-RETEST SCATTERS ####
# reads: artifacts/participant_parameters.rds
# writes: output/test-retest across sessions/{beta,tau,utility}_test_retest_scatter.png
#
# Same style as analysis/beta_tau_halfnormal_stz/code/plot_scalar_param_test_retest.R:
# posterior medians, session 1 on x and session 2 on y, shared axes, identity line
# (dashed) and least-squares line (red).

df_participant_parameters <- readRDS(file.path(artifacts_dir, "participant_parameters.rds"))

# df_wide has one row per point, with columns value_session1 and value_session2
plot_test_retest <- function(df_wide, axis_label, plot_name) {

  shared_limits <- range(c(df_wide$value_session1, df_wide$value_session2))
  axis_breaks   <- seq(shared_limits[1], shared_limits[2], length.out = 4)
  pearson_r     <- cor(df_wide$value_session1, df_wide$value_session2, method = "pearson")

  p <- ggplot(df_wide, aes(x = value_session1, y = value_session2)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60") +
    annotate(
      "text",
      x = Inf, y = Inf,
      label = sprintf("[Pearson r = %.2f]", pearson_r),
      hjust = 1.05, vjust = 1.4,
      size = 3.5, colour = "grey30"
    ) +
    scale_x_continuous(breaks = axis_breaks, labels = ~ sprintf("%.2f", .x)) +
    scale_y_continuous(breaks = axis_breaks, labels = ~ sprintf("%.2f", .x)) +
    coord_equal(xlim = shared_limits, ylim = shared_limits, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = paste("Session 1", axis_label), y = paste("Session 2", axis_label))

  ggsave(
    file.path(output_retest_dir, paste0(plot_name, ".png")),
    plot = p,
    width = 10, height = 8, dpi = 300, bg = "white"
  )
  saveRDS(p, file.path(artifacts_dir, paste0("p_", plot_name, ".rds")))   # for the combined PDF

  p
}

widen_by_session <- function(df_long) {
  df_long |>
    pivot_wider(names_from = session, values_from = value, names_prefix = "value_") |>
    filter(!is.na(value_session1), !is.na(value_session2))
}

# beta and tau: one point per subject
df_beta_wide <- df_participant_parameters |>
  select(session, subject, value = beta) |>
  widen_by_session()

df_tau_wide <- df_participant_parameters |>
  select(session, subject, value = tau) |>
  widen_by_session()

# u: one point per subject x item
df_utility_wide <- df_participant_parameters |>
  select(session, subject, u_1:u_15) |>
  pivot_longer(u_1:u_15, names_to = "item", values_to = "value") |>
  widen_by_session()

stopifnot(nrow(df_beta_wide) == n_subjects,
          nrow(df_tau_wide) == n_subjects,
          nrow(df_utility_wide) == n_subjects * n_options)

p_beta_retest    <- plot_test_retest(df_beta_wide, "beta", "beta_test_retest_scatter")
p_tau_retest     <- plot_test_retest(df_tau_wide, "tau", "tau_test_retest_scatter")
p_utility_retest <- plot_test_retest(df_utility_wide, "utility (u)", "utility_test_retest_scatter")
