#### PLOT RT DISTRIBUTION ####

rt_median <- median(df$rt)
rt_p05    <- quantile(df$rt, 0.05)
rt_p95    <- quantile(df$rt, 0.95)

rt_plot <- df |>
  ggplot(aes(x = rt)) +
  geom_histogram(bins = 30, fill = "#4477AA", color = "white") +
  geom_vline(xintercept = rt_median, linetype = "dashed", color = "grey30") +
  geom_vline(xintercept = rt_p05, linetype = "dashed", color = "grey60") +
  geom_vline(xintercept = rt_p95, linetype = "dashed", color = "grey60") +
  annotate("text", x = rt_median, y = Inf, label = "median", vjust = 2, hjust = -0.1, size = 3, color = "grey30") +
  annotate("text", x = rt_p05, y = Inf, label = "5th pct", vjust = 4, hjust = -0.1, size = 3, color = "grey60") +
  annotate("text", x = rt_p95, y = Inf, label = "95th pct", vjust = 4, hjust = 1.1, size = 3, color = "grey60") +
  labs(
    title = "RT distribution, pairwise-choice trials (pilot session)",
    x = "Reaction time (ms)",
    y = "Count"
  ) +
  theme_minimal()

ggsave(file.path(output_dir, "rt_distribution_pilot.pdf"), rt_plot, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "rt_distribution_pilot.png"), rt_plot, width = 10, height = 8, dpi = 300, bg = "white")
