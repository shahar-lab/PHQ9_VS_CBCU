#### PLOT CROSS-PARAMETER SCATTERS ####
# Cross-parameter comparisons (different scales): coord_equal(), the diagonal reference line and
# shared axis limits are NOT used. beta (~0-20), tau (~-14-11), rho (~-0.6-1.2) and u are on
# unrelated scales, so an equal aspect ratio squashes the plots flat and the diagonal is meaningless.

df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

save_scatter <- function(df_xy, x_label, y_label, plot_name) {
  pearson_r <- cor(df_xy$x, df_xy$y, method = "pearson")

  p <- ggplot(df_xy, aes(x = x, y = y)) +
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

  ggsave(file.path(output_relations_dir, paste0(plot_name, ".pdf")), plot = p, width = 10, height = 8, bg = "white")
  ggsave(file.path(output_relations_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 8, dpi = 300, bg = "white")

  p
}

plot_utility_vs_scalar <- function(df, wave, scalar_param_name, plot_name) {
  df_long <- df |>
    filter(time == wave) |>
    select(prolific_id, u_1:u_15, y = all_of(scalar_param_name)) |>
    pivot_longer(u_1:u_15, names_to = "item", values_to = "x") |>
    filter(!is.na(x), !is.na(y))

  save_scatter(df_long, "Utility (u)", scalar_param_name, plot_name)
}

plot_scalar_vs_scalar <- function(df, wave, x_param_name, y_param_name, plot_name) {
  df_wave <- df |>
    filter(time == wave) |>
    select(prolific_id, x = all_of(x_param_name), y = all_of(y_param_name)) |>
    filter(!is.na(x), !is.na(y))

  save_scatter(df_wave, x_param_name, y_param_name, plot_name)
}

for (wave in waves) {
  for (scalar in c("beta", "tau", "rho")) {
    plot_utility_vs_scalar(df_participant_parameters, wave, scalar, paste0("u_vs_", scalar, "_", wave))
  }

  plot_scalar_vs_scalar(df_participant_parameters, wave, "beta", "tau", paste0("beta_vs_tau_", wave))
  plot_scalar_vs_scalar(df_participant_parameters, wave, "beta", "rho", paste0("beta_vs_rho_", wave))
  plot_scalar_vs_scalar(df_participant_parameters, wave, "tau",  "rho", paste0("tau_vs_rho_",  wave))
}
