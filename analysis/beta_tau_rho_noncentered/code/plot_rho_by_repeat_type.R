#### PLOT RHO OF A/B REPEATERS VS NEITHER REPEATERS ####
# reads: artifacts/repeat_types.csv · writes: output/repeat types vs rho/rho_by_repeat_type_dot_histogram.{pdf,png}
# A repeater pressed the same response as on the previous trial on at least
# repeater_threshold of the within-block consecutive pairs: A->A or B->B for A/B
# repeaters, skip->skip for neither repeaters. The two rates sum to at most 1, so with a
# threshold above 0.5 nobody is both. Everyone else is shown in grey for reference.
# The A/B group is too small for a test, so the plot is descriptive only.

df_repeat_types <- read_csv(file.path(artifacts_dir, "repeat_types.csv"), show_col_types = FALSE)

df_repeater_groups <- df_repeat_types |>
  mutate(group = case_when(
    key_raw >= repeater_threshold     ~ "A/B repeaters",
    neither_raw >= repeater_threshold ~ "Neither repeaters",
    .default                          = "Other participants"
  )) |>
  mutate(group = factor(group, levels = c("Other participants", "Neither repeaters", "A/B repeaters")))

write_csv(df_repeater_groups, file.path(artifacts_dir, "repeater_groups.csv"))

# Shared x-axis across sessions: observed range widened 10%, ticks every 0.25 with 0 included
r           <- range(df_repeater_groups$rho)
full_range  <- c(r[1] - 0.10 * diff(r), r[2] + 0.10 * diff(r))
axis_breaks <- seq(ceiling(full_range[1] / 0.25) * 0.25, floor(full_range[2] / 0.25) * 0.25, by = 0.25)

group_colours <- c("A/B repeaters" = "#4477AA", "Neither repeaters" = "#228833", "Other participants" = "grey60")

plot_session <- function(wave) {
  df_wave <- filter(df_repeater_groups, time == wave)

  group_labels <- df_wave |>
    group_by(group, .drop = FALSE) |>
    summarise(n = n(), mean_rho = mean(rho), .groups = "drop") |>
    mutate(label = if_else(n == 0, sprintf("%s\n(n = 0)", group),
                           sprintf("%s\n(n = %d, mean rho = %.2f)", group, n, mean_rho)))

  ggplot(df_wave, aes(x = rho, y = group, fill = group, colour = group)) +
    geom_dots(layout = "bin", binwidth = NA, alpha = 0.7) +
    scale_fill_manual(values = group_colours, guide = "none") +
    scale_colour_manual(values = group_colours, guide = "none") +
    scale_y_discrete(drop = FALSE, labels = setNames(group_labels$label, group_labels$group)) +
    scale_x_continuous(breaks = axis_breaks) +
    coord_cartesian(xlim = full_range, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(
      x     = "rho (posterior median)",
      y     = NULL,
      title = sprintf("%s: repeaters = same response as the previous trial on >= %.0f%% of pairs",
                      if_else(wave == "time1", "Time 1", "Time 2"), 100 * repeater_threshold)
    )
}

p_rho_by_repeat_type <- (plot_session("time1") / plot_session("time2")) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

plot_name <- "rho_by_repeat_type_dot_histogram"

ggsave(file.path(output_repeat_dir, paste0(plot_name, ".pdf")), plot = p_rho_by_repeat_type, width = 10, height = 8, bg = "white")
ggsave(file.path(output_repeat_dir, paste0(plot_name, ".png")), plot = p_rho_by_repeat_type, width = 10, height = 8, dpi = 300, bg = "white")
