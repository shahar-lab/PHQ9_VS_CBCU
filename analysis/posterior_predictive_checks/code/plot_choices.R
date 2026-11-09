#### PLOT THE CHOICE COMPARISONS ####

# Overall proportions: observed (point) against the simulated median and 90% interval
p_props <- df_choice_props |>
  ggplot(aes(x = outcome, colour = time)) +
  geom_linerange(aes(ymin = sim_q05, ymax = sim_q95), position = position_dodge(width = 0.5), linewidth = 1.2, alpha = 0.5) +
  geom_point(aes(y = sim_median, shape = "simulated median"), position = position_dodge(width = 0.5), size = 2) +
  geom_point(aes(y = observed, shape = "observed"), position = position_dodge(width = 0.5), size = 3) +
  scale_shape_manual(values = c(`simulated median` = 1, observed = 19), name = NULL) +
  facet_wrap(~ model) +
  labs(x = NULL, y = "Share of all trials", colour = NULL) +
  theme_bw() +
  theme(legend.position = "bottom")
ggsave(file.path(output_dir, "ppc_choice_proportions.png"), p_props, width = 11, height = 5, dpi = 150)
ggsave(file.path(output_dir, "ppc_choice_proportions.pdf"), p_props, width = 11, height = 5)

# Accuracy per participant (pooled over sessions), participants sorted by accuracy
p_acc <- df_accuracy_participant |>
  group_by(model) |>
  arrange(accuracy, .by_group = TRUE) |>
  mutate(rank = row_number()) |>
  ungroup() |>
  ggplot(aes(x = rank)) +
  geom_point(aes(y = accuracy_time1, colour = "time1"), size = 0.8, alpha = 0.5) +
  geom_point(aes(y = accuracy_time2, colour = "time2"), size = 0.8, alpha = 0.5) +
  geom_point(aes(y = accuracy), size = 1.2) +
  scale_colour_manual(values = c(time1 = "#2980b9", time2 = "#e67e22"), name = "single session") +
  facet_wrap(~ model) +
  labs(x = "Participants, sorted by pooled accuracy", y = "Share of trials predicted correctly",
       subtitle = "Black: both sessions pooled. Coloured: each session separately.") +
  theme_bw() +
  theme(legend.position = "bottom")
ggsave(file.path(output_dir, "ppc_choice_accuracy_per_participant.png"), p_acc, width = 11, height = 5, dpi = 150)

# Calibration: predicted probability against observed frequency, per outcome and model
p_cal <- df_calibration |>
  filter(n_trials >= 20) |>
  ggplot(aes(x = mean_predicted, y = observed_rate, size = n_trials)) +
  geom_abline(slope = 1, intercept = 0, colour = "grey50") +
  geom_point(alpha = 0.7) +
  scale_size_area(max_size = 5, name = "trials in bin") +
  facet_grid(outcome ~ model) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(x = "Simulated probability of the outcome", y = "Observed frequency of the outcome") +
  theme_bw() +
  theme(legend.position = "bottom")
ggsave(file.path(output_dir, "ppc_choice_calibration.png"), p_cal, width = 11, height = 9, dpi = 150)
ggsave(file.path(output_dir, "ppc_choice_calibration.pdf"), p_cal, width = 11, height = 9)
