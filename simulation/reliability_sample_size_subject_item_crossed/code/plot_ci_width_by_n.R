#### PLOT HDI WIDTH BY SAMPLE SIZE, ONCE PER OUTCOME ####

pal <- c("85" = "#4477AA", "90" = "#CCBB44", "95" = "#EE6677")

# Two outcomes share the same plot structure, only the input results table,
# title, and filename differ -- a custom function avoids duplicating the
# plotting code (per coding-rules.md).
plot_hdi_width_by_n <- function(sweep_results, plot_title, plot_name) {

  plot_df <- sweep_results |>
    pivot_longer(
      cols      = c(hdi_width_85, hdi_width_90, hdi_width_95),
      names_to  = "credible_level",
      values_to = "hdi_width"
    ) |>
    mutate(
      credible_level = credible_level |>
        str_remove("hdi_width_") |>
        factor(levels = c("85", "90", "95"))
    )

  p <- ggplot(plot_df, aes(x = sample_size, y = hdi_width, colour = credible_level)) +
    geom_line(aes(group = credible_level), linewidth = 0.5, alpha = 0.6) +
    geom_point(size = 2, alpha = 0.8) +
    scale_colour_manual(values = pal) +
    scale_x_continuous(breaks = sample_sizes) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid           = element_blank(),
      axis.line.x          = element_line(colour = "grey30"),
      axis.line.y          = element_line(colour = "grey30"),
      legend.position       = c(1, 0.95),
      legend.justification  = c("right", "top"),
      legend.background     = element_blank(),
      legend.key            = element_blank()
    ) +
    labs(
      title  = plot_title,
      x      = "Sample size (N)",
      y      = "HDI width (subject ICC)",
      colour = "Credible level (%)"
    )

  ggsave(
    file.path(output_dir, paste0(plot_name, ".pdf")),
    plot = p, width = 10, height = 8, bg = "white"
  )

  ggsave(
    file.path(output_dir, paste0(plot_name, ".png")),
    plot = p, width = 10, height = 8, dpi = 300, bg = "white"
  )
}

plot_hdi_width_by_n(
  sweep_results_cbcu,
  plot_title = "CBCU utilities: subject-ICC HDI width by sample size",
  plot_name  = "hdi_width_subject_icc_cbcu_by_sample_size"
)

plot_hdi_width_by_n(
  sweep_results_phq9,
  plot_title = "PHQ9 items: subject-ICC HDI width by sample size",
  plot_name  = "hdi_width_subject_icc_phq9_by_sample_size"
)
