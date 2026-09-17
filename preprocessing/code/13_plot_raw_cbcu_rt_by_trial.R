# reads: cbcu_results · writes: raw_outputs/13_cbcu_rt_by_trial.{pdf,png}

#### PLOT RAW CBCU RT BY TRIAL ####

raw_cbcu_rt_plot_data <- cbcu_results |>
  dplyr::mutate(prolific_id = as.character(prolific_id)) |>
  dplyr::filter(stats::complete.cases(trial, rt))

x_limits <- range(raw_cbcu_rt_plot_data$trial)
y_limits <- range(raw_cbcu_rt_plot_data$rt)
x_breaks <- round(seq(x_limits[1], x_limits[2], length.out = 4))
y_breaks <- round(seq(y_limits[1], y_limits[2], length.out = 4))
pearson_r <- stats::cor(
  raw_cbcu_rt_plot_data$trial,
  raw_cbcu_rt_plot_data$rt,
  method = "pearson"
)

# ASSUMED[point transparency not quantified]: alpha = 0.35 keeps dense,
# participant-coloured observations visible while preserving overlap.
p_raw_cbcu_rt_by_trial <- ggplot2::ggplot(
  raw_cbcu_rt_plot_data,
  ggplot2::aes(x = trial, y = rt, colour = prolific_id)
) +
  ggplot2::geom_point(alpha = 0.35, size = 1.5) +
  ggplot2::geom_smooth(
    ggplot2::aes(group = 1),
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    colour = "#EE6677",
    linewidth = 0.8
  ) +
  ggplot2::annotate(
    "text", x = Inf, y = Inf,
    label = sprintf("[Pearson r = %.2f]", pearson_r),
    hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30"
  ) +
  ggplot2::scale_colour_viridis_d(option = "D", end = 0.9) +
  ggplot2::scale_x_continuous(breaks = x_breaks) +
  ggplot2::scale_y_continuous(breaks = y_breaks) +
  ggplot2::theme_minimal(base_size = 13) +
  ggplot2::theme(
    aspect.ratio = 1,
    panel.grid.minor = ggplot2::element_blank()
  ) +
  ggplot2::labs(
    title = "Raw CBCU response time by trial",
    x = "CBCU trial number",
    y = "RT (ms)",
    colour = "Participant"
  )

raw_cbcu_rt_plot_name <- "13_cbcu_rt_by_trial"

p_raw_cbcu_rt_by_trial_1000 <- p_raw_cbcu_rt_by_trial +
  ggplot2::coord_cartesian(ylim = c(0, 1000))

p_raw_cbcu_rt_by_trial_3000 <- p_raw_cbcu_rt_by_trial +
  ggplot2::coord_cartesian(ylim = c(0, 3000))

grDevices::pdf(
  file.path(raw_output_dir, paste0(raw_cbcu_rt_plot_name, ".pdf")),
  width = 10, height = 8, bg = "white"
)
print(p_raw_cbcu_rt_by_trial)
print(p_raw_cbcu_rt_by_trial_1000)
print(p_raw_cbcu_rt_by_trial_3000)
grDevices::dev.off()

ggplot2::ggsave(
  file.path(raw_output_dir, paste0(raw_cbcu_rt_plot_name, ".png")),
  plot = p_raw_cbcu_rt_by_trial,
  width = 10, height = 8, dpi = 300, bg = "white"
)
