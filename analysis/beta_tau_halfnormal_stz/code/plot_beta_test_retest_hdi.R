#### PLOT BETA TEST-RETEST SCATTER WITH 95% HDI WHISKERS ####
# reads:  artifacts/beta_posterior_width.csv (from plot_beta_posterior_width.R:
#         posterior median and 95% HDI of beta per participant x wave)
# writes: output/test-retest across sessions/correlation/beta_test_retest_hdi_scatter.png
#
# beta_test_retest_scatter.png with each participant's uncertainty: the dot is the posterior
# median (time 1 on x, time 2 on y); the horizontal whisker is the time 1 95% HDI and the
# vertical whisker the time 2 95% HDI. Linear axes, shared by x and y, wide enough for all whiskers.

df_beta_hdi <- read_csv(file.path(artifacts_dir, "beta_posterior_width.csv"), show_col_types = FALSE) |>
  select(prolific_id, time, median = beta_median, lower = hdi_lower, upper = hdi_upper) |>
  pivot_wider(names_from = time, values_from = c(median, lower, upper)) |>
  filter(!is.na(median_time1), !is.na(median_time2))

pearson_r_beta <- cor(df_beta_hdi$median_time1, df_beta_hdi$median_time2)

hdi_limits <- range(c(0, df_beta_hdi$lower_time1, df_beta_hdi$upper_time1,
                      df_beta_hdi$lower_time2, df_beta_hdi$upper_time2))   # beta > 0: start at 0

p_beta_retest_hdi <- ggplot(df_beta_hdi, aes(x = median_time1, y = median_time2)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60") +
  geom_errorbar(aes(xmin = lower_time1, xmax = upper_time1), orientation = "y", width = 0,
                colour = "#4477AA", alpha = 0.25, linewidth = 0.4) +
  geom_errorbar(aes(ymin = lower_time2, ymax = upper_time2), width = 0,
                colour = "#4477AA", alpha = 0.25, linewidth = 0.4) +
  geom_point(colour = "#4477AA", alpha = 0.9, size = 2) +
  geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
  annotate("text", x = Inf, y = Inf,
           label = sprintf("[Pearson r of medians = %.2f]", pearson_r_beta),
           hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
  scale_x_continuous(breaks = scales::breaks_pretty(n = 6)) +
  scale_y_continuous(breaks = scales::breaks_pretty(n = 6)) +
  coord_equal(xlim = hdi_limits, ylim = hdi_limits, clip = "off") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "Time 1 beta (posterior median, 95% HDI)",
       y = "Time 2 beta (posterior median, 95% HDI)",
       caption = sprintf("%d participants. Whiskers: 95%% HDI of each wave's posterior. Dashed: time 1 = time 2.",
                         nrow(df_beta_hdi)))

ggsave(file.path(output_retest_corr_dir, "beta_test_retest_hdi_scatter.png"),
       plot = p_beta_retest_hdi, width = 10, height = 8, dpi = 300, bg = "white")
