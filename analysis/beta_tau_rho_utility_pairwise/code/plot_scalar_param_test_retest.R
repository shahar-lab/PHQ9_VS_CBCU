#### PLOT SCALAR PARAMETER TEST-RETEST SCATTERS ####

df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

plot_param_test_retest <- function(df, param_name, param_label) {

  df_param_wide <- df |>
    select(prolific_id, time, value = all_of(param_name)) |>
    pivot_wider(names_from = time, values_from = value, names_prefix = "value_") |>
    filter(!is.na(value_time1), !is.na(value_time2))

  shared_limits <- range(c(df_param_wide$value_time1, df_param_wide$value_time2))
  axis_breaks   <- round(seq(shared_limits[1], shared_limits[2], length.out = 4), 2)
  pearson_r     <- cor(df_param_wide$value_time1, df_param_wide$value_time2, method = "pearson")

  p <- ggplot(df_param_wide, aes(x = value_time1, y = value_time2)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
    geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
    annotate("text", x = Inf, y = Inf, label = sprintf("[Pearson r = %.2f]", pearson_r),
             hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
    scale_x_continuous(breaks = axis_breaks) +
    scale_y_continuous(breaks = axis_breaks) +
    coord_equal(xlim = shared_limits, ylim = shared_limits, clip = "off") +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = paste("Time 1", param_label), y = paste("Time 2", param_label))

  plot_name <- paste0(param_name, "_test_retest_scatter")
  ggsave(file.path(output_retest_dir, paste0(plot_name, ".pdf")), plot = p, width = 10, height = 8, bg = "white")
  ggsave(file.path(output_retest_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 8, dpi = 300, bg = "white")

  p
}

p_tau_retest  <- plot_param_test_retest(df_participant_parameters, "tau", "tau")
p_beta_retest <- plot_param_test_retest(df_participant_parameters, "beta", "beta")
p_rho_retest  <- plot_param_test_retest(df_participant_parameters, "rho", "rho")

pdf(file.path(output_retest_dir, "test_retest_summary.pdf"), width = 10, height = 8)
print(p_tau_retest)
print(p_beta_retest)
print(p_rho_retest)
dev.off()
