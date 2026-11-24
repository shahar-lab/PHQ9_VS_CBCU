#### PLOT TEST-RETEST SCATTERS (TIME 1 VS TIME 2) ####
# reads: artifacts/participant_parameters.csv, artifacts/sigma_draws_by_wave.rds
# writes: output/test-retest across sessions/correlation/{sigma,tau,utility,phq9_sum}_test_retest_scatter.png
#
# Posterior medians, time 1 on x and time 2 on y, shared axes, identity line (dashed),
# least-squares line (red), Pearson r. sigma also gets each participant's 95% HDI as
# whiskers. Axes cover the parameter's range: sigma from 0; tau and u symmetric about 0;
# PHQ-9 sum 0-27. Only participants with both times are plotted.

df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)
sigma_draws <- readRDS(file.path(artifacts_dir, "sigma_draws_by_wave.rds"))

hdi_prob <- 0.95

# Shortest interval containing prob of the draws
hdi_bounds <- function(x, prob) {
  x       <- sort(x)
  n_in    <- ceiling(prob * length(x))
  widths  <- x[n_in:length(x)] - x[1:(length(x) - n_in + 1)]
  i_start <- which.min(widths)
  c(x[i_start], x[i_start + n_in - 1])
}

# range = "positive": [0, max + 20% of the data range]; "symmetric": [-m, m], m = max |value| + 5%
axis_limits <- function(values, range) {
  switch(range,
         positive  = c(0, max(values) + 0.20 * diff(range(values))),
         symmetric = c(-1, 1) * 1.05 * max(abs(values)),
         phq9_sum  = c(0, 27))
}

# df_wide: one row per point, value_time1 / value_time2, optionally lower_/upper_time1/2
plot_test_retest <- function(df_wide, axis_label, plot_name, range) {

  has_interval  <- "lower_time1" %in% names(df_wide)
  limit_columns <- if (has_interval) c("lower_time1", "upper_time1", "lower_time2", "upper_time2")
                   else c("value_time1", "value_time2")
  shared_limits <- axis_limits(unlist(df_wide[limit_columns]), range)
  axis_breaks   <- scales::breaks_pretty(n = 5)(shared_limits)
  pearson_r     <- cor(df_wide$value_time1, df_wide$value_time2)

  p <- ggplot(df_wide, aes(x = value_time1, y = value_time2)) +
    {if (has_interval) list(
      geom_errorbar(aes(xmin = lower_time1, xmax = upper_time1), orientation = "y", width = 0,
                    colour = "#4477AA", alpha = 0.25, linewidth = 0.4),
      geom_errorbar(aes(ymin = lower_time2, ymax = upper_time2), width = 0,
                    colour = "#4477AA", alpha = 0.25, linewidth = 0.4)
    )} +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60") +
    annotate("text", x = Inf, y = Inf, label = sprintf("[Pearson r = %.2f]", pearson_r),
             hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
    scale_x_continuous(breaks = axis_breaks) +
    scale_y_continuous(breaks = axis_breaks) +
    coord_equal(xlim = shared_limits, ylim = shared_limits, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = paste("Time 1", axis_label), y = paste("Time 2", axis_label),
         caption = if (has_interval) sprintf("Dot: posterior median. Whiskers: %d%% HDI of each time's posterior.",
                                             round(100 * hdi_prob)))

  ggsave(file.path(output_retest_corr_dir, paste0(plot_name, ".png")),
         plot = p, width = 10, height = 8, dpi = 300, bg = "white")

  p
}

widen_by_time <- function(df_long) {
  df_long |>
    pivot_wider(names_from = time, values_from = value, names_prefix = "value_") |>
    filter(!is.na(value_time1), !is.na(value_time2))
}

# sigma: median and 95% HDI per participant x time
df_sigma_hdi <- imap_dfr(sigma_draws, function(sigma_mat, wave) {
  hdi <- apply(sigma_mat, 2, hdi_bounds, prob = hdi_prob)   # row 1 lower, row 2 upper
  tibble(prolific_id = colnames(sigma_mat), time = wave, lower = hdi[1, ], upper = hdi[2, ])
})

df_sigma_wide <- df_participant_parameters |>
  select(prolific_id, time, value = sigma) |>
  left_join(df_sigma_hdi, by = c("prolific_id", "time")) |>
  pivot_wider(names_from = time, values_from = c(value, lower, upper)) |>
  filter(!is.na(value_time1), !is.na(value_time2))

stopifnot(!anyNA(df_sigma_wide))

df_tau_wide <- df_participant_parameters |>
  select(prolific_id, time, value = tau) |>
  widen_by_time()

df_utility_wide <- df_participant_parameters |>
  select(prolific_id, time, u_1:u_15) |>
  pivot_longer(u_1:u_15, names_to = "item", values_to = "value") |>
  widen_by_time()

df_phq9_wide <- df_participant_parameters |>
  select(prolific_id, time, value = phq9_sum) |>
  widen_by_time()

cat(sprintf("Test-retest: %d participants with both times\n", nrow(df_sigma_wide)))

p_sigma_retest   <- plot_test_retest(df_sigma_wide, "sigma", "sigma_test_retest_scatter", "positive")
p_tau_retest     <- plot_test_retest(df_tau_wide, "tau (None utility)", "tau_test_retest_scatter", "symmetric")
p_utility_retest <- plot_test_retest(df_utility_wide, "utility (u)", "utility_test_retest_scatter", "symmetric")
p_phq9_retest    <- plot_test_retest(df_phq9_wide, "PHQ-9 sum", "phq9_sum_test_retest_scatter", "phq9_sum")

p_retest_summary <- wrap_plots(p_sigma_retest, p_tau_retest, p_utility_retest, p_phq9_retest, ncol = 2) +
  plot_annotation(title = "Test-retest: time 1 vs time 2", tag_levels = "A")

ggsave(file.path(output_retest_corr_dir, "test_retest_summary.pdf"), plot = p_retest_summary,
       width = 14, height = 14, bg = "white")
