#### PLOT INDIVIDUAL RECOVERY ####
# reads: artifacts/recovered_parameters.rds
# writes: output/06_<parameter>_recovery.pdf/png, 06_full_recovery_panel.pdf/png, artifacts/p_full_recovery_panel.rds

recovered_parameters <- readRDS(file.path(artifacts_dir, "recovered_parameters.rds"))

# Scatter of recovered (posterior mean) against true, with the identity line.
# log_axes = TRUE puts both axes on a log scale (used for beta, which is lognormal).
plot_recovery <- function(plot_df, axis_label, log_axes = FALSE) {
  shared_limits <- range(c(plot_df$true_value, plot_df$recovered_value))
  pearson_r     <- if (log_axes) cor(log(plot_df$true_value), log(plot_df$recovered_value))
                   else cor(plot_df$true_value, plot_df$recovered_value)
  r_label       <- sprintf(if (log_axes) "[Pearson r (log scale) = %.2f]" else "[Pearson r = %.2f]", pearson_r)

  if (log_axes) {
    axis_breaks <- exp(seq(log(shared_limits[1]), log(shared_limits[2]), length.out = 4))
    x_scale <- scale_x_log10(breaks = axis_breaks, labels = function(b) round(b, 1))
    y_scale <- scale_y_log10(breaks = axis_breaks, labels = function(b) round(b, 1))
  } else {
    axis_breaks <- seq(shared_limits[1], shared_limits[2], length.out = 4)
    x_scale <- scale_x_continuous(breaks = axis_breaks, labels = function(b) round(b, 2))
    y_scale <- scale_y_continuous(breaks = axis_breaks, labels = function(b) round(b, 2))
  }

  ggplot(plot_df, aes(x = true_value, y = recovered_value)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2.5) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
    annotate("text", x = Inf, y = Inf, label = r_label,
             hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
    x_scale + y_scale +
    coord_equal(xlim = shared_limits, ylim = shared_limits, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = paste("True", axis_label), y = paste("Recovered", axis_label))
}

recovery_plots <- list(
  u        = plot_recovery(filter(recovered_parameters, parameter == "u"), "utility (u)"),
  beta     = plot_recovery(filter(recovered_parameters, parameter == "beta"), "beta"),
  beta_log = plot_recovery(filter(recovered_parameters, parameter == "beta"), "beta (log axes)", log_axes = TRUE),
  tau      = plot_recovery(filter(recovered_parameters, parameter == "tau"), "tau")
)

for (param in names(recovery_plots)) {
  file_stem <- file.path(output_dir, paste0("06_", param, "_recovery"))
  ggsave(paste0(file_stem, ".pdf"), plot = recovery_plots[[param]], width = 10, height = 8, bg = "white")
  ggsave(paste0(file_stem, ".png"), plot = recovery_plots[[param]], width = 10, height = 8, dpi = 300, bg = "white")
}

p_full_recovery_panel <- (recovery_plots$u | recovery_plots$tau) / (recovery_plots$beta | recovery_plots$beta_log) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "06_full_recovery_panel.pdf"), plot = p_full_recovery_panel, width = 14, height = 12, bg = "white")
ggsave(file.path(output_dir, "06_full_recovery_panel.png"), plot = p_full_recovery_panel, width = 14, height = 12, dpi = 300, bg = "white")
saveRDS(p_full_recovery_panel, file.path(artifacts_dir, "p_full_recovery_panel.rds"))
