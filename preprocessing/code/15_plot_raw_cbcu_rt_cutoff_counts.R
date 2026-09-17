# reads: cbcu_results · writes: raw_outputs/15_cbcu_rt_cutoff_counts.{pdf,png}

#### PLOT RAW CBCU RT CUTOFF COUNTS ####

raw_cbcu_complete_rt <- cbcu_results |>
  filter(!is.na(rt)) |>
  pull(rt)

if (length(raw_cbcu_complete_rt) == 0) {
  stop("Cannot count CBCU RT cutoffs without non-missing RT values.")
}

lower_rt_limits_ms <- seq(0, 1000, by = 50)
upper_rt_limits_s  <- seq(5, 10, by = 1)

lower_rt_count_data <- tibble(
  rt_limit_ms = lower_rt_limits_ms,
  trial_count = map_int(
    lower_rt_limits_ms,
    \(limit) sum(raw_cbcu_complete_rt <= limit)
  )
)

upper_rt_count_data <- tibble(
  rt_limit_s = upper_rt_limits_s,
  trial_count = map_int(
    upper_rt_limits_s,
    \(limit) sum(raw_cbcu_complete_rt >= limit * 1000)
  )
)

# ASSUMED[plot geometry not specified]: connect cutoff counts with lines and
# show each requested cutoff with a point.
p_lower_rt_counts <- ggplot(
  lower_rt_count_data,
  aes(x = rt_limit_ms, y = trial_count)
) +
  geom_line(linewidth = 0.8, colour = "#4477AA") +
  geom_point(size = 2, colour = "#4477AA") +
  scale_x_continuous(breaks = seq(0, 1000, by = 200)) +
  scale_y_continuous(
    limits = c(0, NA),
    labels = scales::label_comma(),
    expand = expansion(mult = c(0, 0.05))
  ) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(
    title = "Trials at or below lower RT limits",
    x = "Lower RT limit (ms)",
    y = "Number of CBCU trials"
  )

p_upper_rt_counts <- ggplot(
  upper_rt_count_data,
  aes(x = rt_limit_s, y = trial_count)
) +
  geom_line(linewidth = 0.8, colour = "#CC6677") +
  geom_point(size = 2, colour = "#CC6677") +
  scale_x_continuous(breaks = upper_rt_limits_s) +
  scale_y_continuous(
    limits = c(0, NA),
    labels = scales::label_comma(),
    expand = expansion(mult = c(0, 0.05))
  ) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(
    title = "Trials at or above upper RT limits",
    x = "Upper RT limit (s)",
    y = "Number of CBCU trials"
  )

p_raw_cbcu_rt_cutoff_counts <- (p_lower_rt_counts | p_upper_rt_counts) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

raw_cbcu_rt_cutoff_plot_name <- "15_cbcu_rt_cutoff_counts"

ggsave(
  file.path(raw_output_dir, paste0(raw_cbcu_rt_cutoff_plot_name, ".pdf")),
  plot = p_raw_cbcu_rt_cutoff_counts,
  width = 10, height = 8, bg = "white"
)

ggsave(
  file.path(raw_output_dir, paste0(raw_cbcu_rt_cutoff_plot_name, ".png")),
  plot = p_raw_cbcu_rt_cutoff_counts,
  width = 10, height = 8, dpi = 300, bg = "white"
)
