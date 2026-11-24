#### PLOT PARAMETER TEST-RETEST SCATTERS ####
# reads: artifacts/participant_parameters.rds, artifacts/draws_<session>.rds (beta HDI)
# writes: output/test-retest across sessions/{beta,tau,utility}_test_retest_scatter.png
#
# Same style as analysis/beta_tau_halfnormal_stz/code/plot_scalar_param_test_retest.R:
# posterior medians, session 1 on x and session 2 on y, shared axes, identity line
# (dashed) and least-squares line (red). Beta also gets each subject's 95% HDI as whiskers
# (horizontal = session 1, vertical = session 2), as in the real-data
# beta_test_retest_hdi_scatter.png; the shared axes then widen to fit every whisker.

df_participant_parameters <- readRDS(file.path(artifacts_dir, "participant_parameters.rds"))

hdi_prob <- 0.95

# Shortest interval containing prob of the draws (as in the real-data analysis)
hdi_bounds <- function(x, prob) {
  x       <- sort(x)
  n_in    <- ceiling(prob * length(x))
  widths  <- x[n_in:length(x)] - x[1:(length(x) - n_in + 1)]
  i_start <- which.min(widths)
  c(x[i_start], x[i_start + n_in - 1])
}

# df_wide has one row per point, with columns value_session1 and value_session2, and
# optionally lower_/upper_session1 and lower_/upper_session2 (drawn as whiskers)
plot_test_retest <- function(df_wide, axis_label, plot_name) {

  has_interval  <- all(c("lower_session1", "upper_session1", "lower_session2", "upper_session2") %in% names(df_wide))
  limit_columns <- if (has_interval) c("lower_session1", "upper_session1", "lower_session2", "upper_session2")
                   else c("value_session1", "value_session2")
  shared_limits <- range(unlist(df_wide[limit_columns]))
  axis_breaks   <- seq(shared_limits[1], shared_limits[2], length.out = 4)
  pearson_r     <- cor(df_wide$value_session1, df_wide$value_session2, method = "pearson")

  p <- ggplot(df_wide, aes(x = value_session1, y = value_session2)) +
    {if (has_interval) list(
      geom_errorbar(aes(xmin = lower_session1, xmax = upper_session1), orientation = "y", width = 0,
                    colour = "#4477AA", alpha = 0.25, linewidth = 0.4),
      geom_errorbar(aes(ymin = lower_session2, ymax = upper_session2), width = 0,
                    colour = "#4477AA", alpha = 0.25, linewidth = 0.4)
    )} +
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
    labs(x = paste("Session 1", axis_label), y = paste("Session 2", axis_label),
         caption = if (has_interval) sprintf("Dot: posterior median. Whiskers: %d%% HDI of each session's posterior.",
                                             round(100 * hdi_prob)))

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

# 95% HDI of beta per subject x session, from the posterior draws
df_beta_hdi <- map_dfr(paste0("session", 1:n_sessions), function(session) {
  beta_draws <- as_draws_matrix(subset_draws(readRDS(file.path(artifacts_dir, paste0("draws_", session, ".rds"))),
                                             variable = "beta"))
  beta_hdi   <- unname(apply(unclass(beta_draws), 2, hdi_bounds, prob = hdi_prob))   # row 1 lower, row 2 upper
  tibble(session = session,
         subject = as.integer(str_extract(colnames(beta_draws), "\\d+")),
         lower   = beta_hdi[1, ],
         upper   = beta_hdi[2, ])
})

# beta and tau: one point per subject
df_beta_wide <- df_participant_parameters |>
  select(session, subject, value = beta) |>
  left_join(df_beta_hdi, by = c("session", "subject")) |>
  pivot_wider(names_from = session, values_from = c(value, lower, upper)) |>
  filter(!is.na(value_session1), !is.na(value_session2))

stopifnot(!anyNA(df_beta_wide),
          all(df_beta_wide$lower_session1 <= df_beta_wide$value_session1),
          all(df_beta_wide$value_session2 <= df_beta_wide$upper_session2))

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
