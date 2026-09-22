#### PLOT RT AS A FUNCTION OF TRIAL PRESENTATION ORDER ####

rt_by_trial_plot <- df |>
  ggplot(aes(x = phase_trial_num, y = rt)) +
  geom_point(color = "#4477AA", alpha = 0.75, size = 2) +
  geom_smooth(method = "loess", se = FALSE, color = "#EE6677", linewidth = 0.8) +
  labs(
    title = "RT across trial presentation order (pilot session)",
    x = "Trial number (pairwise phase)",
    y = "Reaction time (ms)"
  ) +
  theme_minimal()

ggsave(file.path(output_dir, "rt_by_trial_pilot.pdf"), rt_by_trial_plot, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "rt_by_trial_pilot.png"), rt_by_trial_plot, width = 10, height = 8, dpi = 300, bg = "white")
