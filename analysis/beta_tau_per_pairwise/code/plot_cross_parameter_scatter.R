# Slightly exceeds the 80-line guideline; kept as one file since the two helpers share a single
# read of participant_parameters.csv and are tightly cohesive -- splitting would not aid clarity.
#### PLOT CROSS-PARAMETER SCATTERS ####
# Cross-parameter comparisons (different scales): coord_equal() and the diagonal reference line are
# used per the lab standard (required on every scatter plot regardless of scale), but shared axis
# limits/tick values are NOT used, since that part of the standard is conditional on x and y being
# on the same measurement scale, which does not hold here (u vs tau, u vs beta, beta vs tau).

df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

plot_utility_vs_scalar <- function(df, wave, scalar_param_name, scalar_param_label, plot_name) {

  df_wave <- df |>
    filter(time == wave) |>
    select(prolific_id, u_1:u_15, scalar_value = all_of(scalar_param_name))

  df_long <- df_wave |>
    pivot_longer(u_1:u_15, names_to = "item", values_to = "u") |>
    filter(!is.na(u), !is.na(scalar_value))

  stopifnot(length(df_long$u) == length(df_long$scalar_value))
  pearson_r <- cor(df_long$u, df_long$scalar_value, method = "pearson")

  p <- ggplot(df_long, aes(x = u, y = scalar_value)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
    geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60") +
    annotate(
      "text",
      x = Inf, y = Inf,
      label = sprintf("[Pearson r = %.2f]", pearson_r),
      hjust = 1.05, vjust = 1.4,
      size = 3.5, colour = "grey30"
    ) +
    coord_equal() +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = "Utility (u)", y = scalar_param_label)

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

plot_scalar_vs_scalar <- function(df, wave, x_param_name, x_param_label, y_param_name, y_param_label, plot_name) {

  df_wave <- df |>
    filter(time == wave) |>
    select(prolific_id, x_value = all_of(x_param_name), y_value = all_of(y_param_name)) |>
    filter(!is.na(x_value), !is.na(y_value))

  stopifnot(length(df_wave$x_value) == length(df_wave$y_value))
  pearson_r <- cor(df_wave$x_value, df_wave$y_value, method = "pearson")

  p <- ggplot(df_wave, aes(x = x_value, y = y_value)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
    geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60") +
    annotate(
      "text",
      x = Inf, y = Inf,
      label = sprintf("[Pearson r = %.2f]", pearson_r),
      hjust = 1.05, vjust = 1.4,
      size = 3.5, colour = "grey30"
    ) +
    coord_equal() +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = x_param_label, y = y_param_label)

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

p_u_vs_tau_time1  <- plot_utility_vs_scalar(df_participant_parameters, "time1", "tau", "tau", "u_vs_tau_time1")
p_u_vs_tau_time2  <- plot_utility_vs_scalar(df_participant_parameters, "time2", "tau", "tau", "u_vs_tau_time2")
p_u_vs_beta_time1 <- plot_utility_vs_scalar(df_participant_parameters, "time1", "beta", "beta", "u_vs_beta_time1")
p_u_vs_beta_time2 <- plot_utility_vs_scalar(df_participant_parameters, "time2", "beta", "beta", "u_vs_beta_time2")

p_beta_vs_tau_time1 <- plot_scalar_vs_scalar(df_participant_parameters, "time1", "beta", "beta", "tau", "tau", "beta_vs_tau_time1")
p_beta_vs_tau_time2 <- plot_scalar_vs_scalar(df_participant_parameters, "time2", "beta", "beta", "tau", "tau", "beta_vs_tau_time2")
