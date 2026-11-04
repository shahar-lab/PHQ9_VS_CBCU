# reads: data/processed/cbcu.csv
# writes: output/processed/17_rt_distribution.png, output/processed/17_rt_by_trial.png,
#         output/processed/17_rt_by_trial_linear.png, output/processed/17_rt_by_trial_linear_zoomed.png

#### PLOT RT OF SURVIVING CBCU TRIALS ####

# Descriptive only: RT is not used as an exclusion criterion.
cbcu_processed <- read_csv(file.path(processed_dir, "cbcu.csv"), show_col_types = FALSE) |>
  filter(!is.na(rt), rt > 0)

# Distribution: log-spaced bins, so bins (and axis gaps) widen as RT increases.
rt_edges <- 10^seq(log10(min(cbcu_processed$rt)), log10(max(cbcu_processed$rt)),
                   length.out = 41)

rt_distribution_plot <- ggplot(cbcu_processed, aes(rt)) +
  geom_histogram(breaks = rt_edges, fill = "steelblue", color = "white") +
  scale_x_log10(
    breaks = c(100, 300, 1000, 3000, 10000, 30000, 100000, 300000),
    labels = scales::label_comma()
  ) +
  labs(x = "RT (ms, log-spaced bins)", y = "Trials") +
  theme_minimal()

ggsave(file.path(output_processed_dir, "17_rt_distribution.png"),
       rt_distribution_plot, width = 8, height = 4.5, dpi = 150)

# RT by trial, both sessions overlaid (trial restarts at 1 each session). Every trial is
# one dot; the line is the median across participants.
rt_median_by_trial <- cbcu_processed |>
  group_by(time, trial) |>
  summarise(rt = median(rt), .groups = "drop")

rt_by_trial_plot <- ggplot(cbcu_processed, aes(trial, rt, color = time)) +
  geom_point(size = 0.5, alpha = 0.12,
             position = position_jitter(width = 0.25, height = 0)) +
  geom_line(data = rt_median_by_trial, linewidth = 0.8) +
  scale_y_log10(labels = scales::label_comma()) +
  scale_x_continuous(breaks = seq(0, 105, 15)) +
  scale_color_manual(values = c(time1 = "#d95f02", time2 = "#1b9e77")) +
  guides(color = guide_legend(override.aes = list(alpha = 1, size = 2))) +
  labs(
    x = "Trial", y = "RT (ms, log scale)", color = NULL,
    caption = "Each dot = one trial; line = median across participants"
  ) +
  theme_minimal() +
  theme(legend.position = "top")

ggsave(file.path(output_processed_dir, "17_rt_by_trial.png"),
       rt_by_trial_plot, width = 8, height = 4.5, dpi = 150)

# RT by trial on a linear RT axis, same layout as above. The full-range plot is dominated
# by a few very slow trials, so a second copy zooms the y-axis to 0-15 s (the dots above
# 15 s are cut off from view, not removed from the data).
rt_by_trial_linear_plot <- ggplot(cbcu_processed, aes(trial, rt, color = time)) +
  geom_point(size = 0.5, alpha = 0.12,
             position = position_jitter(width = 0.25, height = 0)) +
  geom_line(data = rt_median_by_trial, linewidth = 0.8) +
  scale_y_continuous(labels = scales::label_comma()) +
  scale_x_continuous(breaks = seq(0, 105, 15)) +
  scale_color_manual(values = c(time1 = "#d95f02", time2 = "#1b9e77")) +
  guides(color = guide_legend(override.aes = list(alpha = 1, size = 2))) +
  labs(
    x = "Trial", y = "RT (ms)", color = NULL,
    caption = "Each dot = one trial; line = median across participants"
  ) +
  theme_minimal() +
  theme(legend.position = "top")

# Full range, drawn taller so the y-axis (0 to the maximum RT) has room.
ggsave(
  file.path(output_processed_dir, "17_rt_by_trial_linear.png"),
  rt_by_trial_linear_plot +
    scale_y_continuous(
      labels = scales::label_comma(),
      limits = c(0, max(cbcu_processed$rt)),
      breaks = seq(0, 450000, 50000)
    ),
  width = 8, height = 10, dpi = 150
)

rt_zoom_max_ms <- 15000
n_above_zoom   <- sum(cbcu_processed$rt > rt_zoom_max_ms)

ggsave(
  file.path(output_processed_dir, "17_rt_by_trial_linear_zoomed.png"),
  rt_by_trial_linear_plot +
    coord_cartesian(ylim = c(0, rt_zoom_max_ms)) +
    labs(caption = paste0(
      "Each dot = one trial; line = median across participants. ",
      "Y-axis cut at ", rt_zoom_max_ms / 1000, " s (", n_above_zoom, " slower trials not shown)"
    )),
  width = 8, height = 4.5, dpi = 150
)
