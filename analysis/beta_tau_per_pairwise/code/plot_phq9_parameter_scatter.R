#### PLOT PHQ9 VS. SESSION-AVERAGED PARAMETER SCATTERS ####
# Different-scale comparisons (PHQ9 vs. u/beta/tau): neither coord_equal() nor the y=x diagonal
# reference line is used here, since x and y are not on the same measurement scale -- forcing a
# 1:1 aspect ratio between e.g. PHQ9 sum (0-27) and utility (~[-2, 2]) collapses the plot into an
# unreadable sliver, and a y=x line has no meaning when the two axes measure different things.

plot_phq9_vs_parameter <- function(df, x_var, x_label, y_var, y_label, plot_name) {

  df_plot <- df |>
    select(x_value = all_of(x_var), y_value = all_of(y_var)) |>
    filter(!is.na(x_value), !is.na(y_value))

  stopifnot(length(df_plot$x_value) == length(df_plot$y_value))
  pearson_r <- cor(df_plot$x_value, df_plot$y_value, method = "pearson")

  p <- ggplot(df_plot, aes(x = x_value, y = y_value)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
    geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    annotate(
      "text",
      x = Inf, y = Inf,
      label = sprintf("[Pearson r = %.2f]", pearson_r),
      hjust = 1.05, vjust = 1.4,
      size = 3.5, colour = "grey30"
    ) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = x_label, y = y_label)

  ggsave(
    file.path(output_dir, paste0(plot_name, ".pdf")),
    plot = p,
    width = 10, height = 8, bg = "white"
  )

  ggsave(
    file.path(output_dir, paste0(plot_name, ".png")),
    plot = p,
    width = 10, height = 8, dpi = 300, bg = "white"
  )

  p
}

p_phq9_sum_vs_utility <- plot_phq9_vs_parameter(df_phq9_parameter_summary, "mean_utility", "Mean utility (u)", "mean_phq9_sum", "PHQ9 sum score (session-averaged)", "phq9_sum_vs_utility")
p_phq9_sum_vs_beta    <- plot_phq9_vs_parameter(df_phq9_parameter_summary, "mean_beta", "Beta", "mean_phq9_sum", "PHQ9 sum score (session-averaged)", "phq9_sum_vs_beta")
p_phq9_sum_vs_tau     <- plot_phq9_vs_parameter(df_phq9_parameter_summary, "mean_tau", "Tau", "mean_phq9_sum", "PHQ9 sum score (session-averaged)", "phq9_sum_vs_tau")

p_phq9_sd_vs_utility <- plot_phq9_vs_parameter(df_phq9_parameter_summary, "mean_utility", "Mean utility (u)", "phq9_item_sd", "PHQ9 item SD", "phq9_sd_vs_utility")
p_phq9_sd_vs_beta    <- plot_phq9_vs_parameter(df_phq9_parameter_summary, "mean_beta", "Beta", "phq9_item_sd", "PHQ9 item SD", "phq9_sd_vs_beta")
p_phq9_sd_vs_tau     <- plot_phq9_vs_parameter(df_phq9_parameter_summary, "mean_tau", "Tau", "phq9_item_sd", "PHQ9 item SD", "phq9_sd_vs_tau")
