#### PLOT SUBJECT-LEVEL PARAMETER DISTRIBUTIONS (POSTERIOR MEDIANS, TIME 1 VS TIME 2) ####

subject_labels <- c(beta = "beta (posterior median per subject)",
                    tau  = "tau (posterior median per subject)",
                    rho  = "rho (posterior median per subject)")

pal <- c("time1" = "#4477AA", "time2" = "#EE6677")

df_subject_params <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE) |>
  select(prolific_id, time, all_of(names(subject_labels))) |>
  pivot_longer(all_of(names(subject_labels)), names_to = "parameter", values_to = "value")

plot_subject_distribution <- function(param_name) {
  df <- filter(df_subject_params, parameter == param_name, !is.na(value))

  stats <- df |>
    group_by(time) |>
    summarise(med = median(value), .groups = "drop") |>
    mutate(label = sprintf("%s: [median = %.2f]", time, med))

  ggplot(df, aes(x = value, y = 0, fill = time, colour = time)) +
    stat_slab(alpha = 0.50) +
    stat_pointinterval(.width = 0.90, point_size = 3) +
    geom_vline(data = stats, aes(xintercept = med, colour = time),
               linetype = "dashed", linewidth = 0.4, show.legend = FALSE) +
    geom_text(data = stats, aes(x = med, y = Inf, label = label, colour = time),
              hjust = -0.05, vjust = seq(1.4, by = 1.4, length.out = nrow(stats)),
              size = 3.2, show.legend = FALSE) +
    scale_fill_manual(values = pal, guide = guide_legend(override.aes = list(alpha = 0.7))) +
    scale_colour_manual(values = pal, guide = "none") +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid             = element_blank(),
      axis.title.y           = element_blank(),
      axis.text.y            = element_blank(),
      axis.ticks.y           = element_blank(),
      axis.line.y            = element_blank(),
      axis.line.x            = element_line(colour = "grey30"),
      legend.position        = "inside",
      legend.position.inside = c(1, 0.95),
      legend.justification   = c("right", "top"),
      legend.background      = element_blank(),
      legend.key             = element_blank()
    ) +
    labs(x = subject_labels[[param_name]], fill = NULL) +
    coord_cartesian(ylim = c(0, 1.3), clip = "off")
}

p_subject <- wrap_plots(map(names(subject_labels), plot_subject_distribution), ncol = 1) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

plot_name <- "posterior_subject_parameters"

ggsave(file.path(output_posterior_dir, paste0(plot_name, ".pdf")), plot = p_subject, width = 10, height = 10, bg = "white")
ggsave(file.path(output_posterior_dir, paste0(plot_name, ".png")), plot = p_subject, width = 10, height = 10, dpi = 300, bg = "white")
