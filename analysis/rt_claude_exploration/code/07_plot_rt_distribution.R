#### PLOT RT DISTRIBUTIONS ####
# reads: artifacts/df_trials.rds · writes: artifacts/p_rt_distribution.rds, output/07_rt_distribution.{pdf,png}

df <- readRDS(file.path(artifacts_dir, "df_trials.rds")) |>
  filter(!is.na(rt)) |>
  mutate(panel = if_else(agent == "Claude", str_replace(unit, "Claude_run", "Claude run "),
                         str_remove(unit, "_time[12]$")))

rt_breaks       <- seq(0, rt_axis_cap, by = 5000)
panel_ratio     <- 1                        # square panels: the y-axis is never longer than the x-axis
max_stack_units <- panel_ratio * rt_axis_cap
bin_widths      <- c(1000, 750, 500, 400, 300, 250, 200, 100)
circle_angles   <- seq(0, 2 * pi, length.out = 25)

# Dot histogram for one panel. Dots are drawn as exact circles (one dot = one trial, stacked per bin) so the
# y-axis is a true count. ASSUMED: ggdist 3.3.3 no longer returns bin ids from ggplot_build(), so the
# geom_dots() count-axis recipe cannot be read off the build.
plot_rt_dots <- function(df_panel, panel_name) {
  n_hidden <- sum(df_panel$rt > rt_axis_cap)
  rt       <- df_panel$rt[df_panel$rt <= rt_axis_cap]

  # largest bin width (ms) whose tallest stack still fits inside the panel
  for (bin_width in bin_widths) {
    if (max(table(floor(rt / bin_width))) * bin_width <= max_stack_units) break
  }

  df_dots <- tibble(rt = rt) |>
    mutate(bin = floor(rt / bin_width), centre_x = (bin + 0.5) * bin_width) |>
    group_by(bin) |>
    mutate(stack = row_number()) |>
    ungroup() |>
    mutate(dot = row_number())

  # coord_fixed(ratio = bin_width): one y-unit is as long as one bin width on x, so circles stay round
  df_circles <- df_dots |>
    reframe(
      x = centre_x + (bin_width / 2) * cos(circle_angles),
      y = (stack - 0.5) + 0.5 * sin(circle_angles),
      .by = dot
    )

  max_stack   <- max(df_dots$stack)
  count_ticks <- unique(round(seq(0, max_stack, length.out = 4)))

  ggplot(df_circles, aes(x = x, y = y, group = dot)) +
    geom_polygon(fill = "gray50", colour = "gray30", linewidth = 0.2) +
    scale_x_continuous(breaks = rt_breaks, labels = \(x) paste0(x / 1000, "k")) +
    scale_y_continuous(name = "Count", breaks = count_ticks) +
    coord_fixed(ratio = bin_width, xlim = c(0, rt_axis_cap), ylim = c(0, max_stack_units / bin_width), expand = FALSE) +
    theme_minimal(base_size = 9) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = sprintf("RT (ms, k = 1000)\nbin %d ms, %d hidden", bin_width, n_hidden),
         subtitle = panel_name)
}

claude_panels <- sort(unique(filter(df, agent == "Claude")$panel))
panel_names   <- c(claude_panels, sort(setdiff(unique(df$panel), claude_panels)))
plots <- map(panel_names, \(panel_name) plot_rt_dots(filter(df, panel == panel_name), panel_name))

p_final <- wrap_plots(plots, ncol = ceiling(sqrt(length(plots)))) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

saveRDS(p_final, file.path(artifacts_dir, "p_rt_distribution.rds"))

plot_name <- "07_rt_distribution"

ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = p_final, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p_final, width = 10, height = 8, dpi = 300, bg = "white")
