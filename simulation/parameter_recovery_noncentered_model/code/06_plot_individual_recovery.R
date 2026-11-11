#### PLOT INDIVIDUAL RECOVERY ####
# reads: artifacts/recovered_parameters.rds
# writes: output/06_<parameter>_recovery.pdf/png, 06_full_recovery_panel.pdf/png, artifacts/p_full_recovery_panel.rds

recovered_parameters <- readRDS(file.path(artifacts_dir, "recovered_parameters.rds"))

axis_labels <- c(u = "utility (u)", beta = "beta", tau = "tau", rho = "rho")
recovery_plots <- list()

for (param in names(axis_labels)) {
  plot_df <- recovered_parameters |> filter(parameter == param)

  shared_limits <- range(c(plot_df$true_value, plot_df$recovered_value))
  axis_breaks   <- seq(shared_limits[1], shared_limits[2], length.out = 4)
  pearson_r     <- cor(plot_df$true_value, plot_df$recovered_value)

  p <- ggplot(plot_df, aes(x = true_value, y = recovered_value)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2.5) +
    geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
    annotate("text", x = Inf, y = Inf, label = sprintf("[Pearson r = %.2f]", pearson_r),
             hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
    scale_x_continuous(breaks = axis_breaks) +
    scale_y_continuous(breaks = axis_breaks) +
    coord_equal(xlim = shared_limits, ylim = shared_limits, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = paste("True", axis_labels[[param]]), y = paste("Recovered", axis_labels[[param]]))

  recovery_plots[[param]] <- p
  file_stem <- file.path(output_dir, paste0("06_", param, "_recovery"))
  ggsave(paste0(file_stem, ".pdf"), plot = p, width = 10, height = 8, bg = "white")
  ggsave(paste0(file_stem, ".png"), plot = p, width = 10, height = 8, dpi = 300, bg = "white")
}

p_full_recovery_panel <- (recovery_plots$u | recovery_plots$beta) / (recovery_plots$tau | recovery_plots$rho) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

ggsave(file.path(output_dir, "06_full_recovery_panel.pdf"), plot = p_full_recovery_panel, width = 14, height = 12, bg = "white")
ggsave(file.path(output_dir, "06_full_recovery_panel.png"), plot = p_full_recovery_panel, width = 14, height = 12, dpi = 300, bg = "white")
saveRDS(p_full_recovery_panel, file.path(artifacts_dir, "p_full_recovery_panel.rds"))
