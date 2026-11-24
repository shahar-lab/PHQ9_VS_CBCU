#### PLOT CHOICE PREDICTION TEST-RETEST SCATTER WITH 95% HDI WHISKERS ####
# reads:  artifacts/choice_prediction_icc_data.csv (from prep_choice_prediction.R:
#         posterior median and 95% HDI of choice prediction per participant x day)
# writes: output/test-retest across sessions/correlation/choice_prediction_test_retest_hdi_scatter.png
#
# Choice prediction = mean P(chosen option) over the participant's trials in that session.
# The dot is the posterior median (time 1 on x, time 2 on y); the horizontal whisker is the
# time 1 95% HDI and the vertical whisker the time 2 95% HDI. Same layout as
# beta_test_retest_hdi_scatter.png: shared linear axes wide enough for all whiskers.

df_cp_hdi <- read_csv(file.path(artifacts_dir, "choice_prediction_icc_data.csv"), show_col_types = FALSE) |>
  select(id, day, median = cp, lower = hdi_lower, upper = hdi_upper) |>
  pivot_wider(names_from = day, values_from = c(median, lower, upper)) |>
  filter(!is.na(median_time1), !is.na(median_time2))

stopifnot(all(df_cp_hdi$lower_time1 <= df_cp_hdi$median_time1),
          all(df_cp_hdi$median_time2 <= df_cp_hdi$upper_time2))

pearson_r_cp <- cor(df_cp_hdi$median_time1, df_cp_hdi$median_time2)

cp_limits <- range(c(df_cp_hdi$lower_time1, df_cp_hdi$upper_time1,
                     df_cp_hdi$lower_time2, df_cp_hdi$upper_time2))
cp_limits[2] <- min(cp_limits[2], 1)   # a probability: never past 1

p_cp_retest_hdi <- ggplot(df_cp_hdi, aes(x = median_time1, y = median_time2)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60") +
  geom_errorbar(aes(xmin = lower_time1, xmax = upper_time1), orientation = "y", width = 0,
                colour = "#4477AA", alpha = 0.25, linewidth = 0.4) +
  geom_errorbar(aes(ymin = lower_time2, ymax = upper_time2), width = 0,
                colour = "#4477AA", alpha = 0.25, linewidth = 0.4) +
  geom_point(colour = "#4477AA", alpha = 0.9, size = 2) +
  geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
  annotate("text", x = Inf, y = Inf,
           label = sprintf("[Pearson r of medians = %.2f]", pearson_r_cp),
           hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
  scale_x_continuous(breaks = scales::breaks_pretty(n = 6)) +
  scale_y_continuous(breaks = scales::breaks_pretty(n = 6)) +
  coord_equal(xlim = cp_limits, ylim = cp_limits, clip = "off") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "Time 1 choice prediction (posterior median, 95% HDI)",
       y = "Time 2 choice prediction (posterior median, 95% HDI)",
       caption = sprintf(paste0("%d participants. Choice prediction: mean P(chosen option) over the session's trials.\n",
                                "Whiskers: 95%% HDI of each day's posterior. Dashed: time 1 = time 2."),
                         nrow(df_cp_hdi)))

ggsave(file.path(output_retest_corr_dir, "choice_prediction_test_retest_hdi_scatter.png"),
       plot = p_cp_retest_hdi, width = 10, height = 8, dpi = 300, bg = "white")
