#### PLOT CHOICE SHARES AND STAY RATES ####
# reads: artifacts/choice_stay_rates.csv · writes: output/choice and stay rates/{choice_share,stay_rate}_dot_histograms.{pdf,png}
# One dot per participant. Rows = measure, columns = session. Red line = median.
# Stay-rate panels leave out participants who never made that choice (n shown per panel).

df_choice_stay_rates <- read_csv(file.path(artifacts_dir, "choice_stay_rates.csv"), show_col_types = FALSE)

measure_labels <- c(
  share_a       = "Chose A",
  share_b       = "Chose B",
  share_neither = "Chose neither",
  stay_neither  = "Neither -> neither",
  stay_a        = "A -> A",
  stay_b        = "B -> B",
  stay_key      = "A or B -> A or B"
)

plot_measures <- function(measures, x_label, plot_name) {
  df_long <- df_choice_stay_rates |>
    pivot_longer(all_of(measures), names_to = "measure", values_to = "value") |>
    filter(!is.na(value)) |>
    mutate(measure = factor(measure_labels[measure], levels = measure_labels[measures]),
           time    = if_else(time == "time1", "Time 1", "Time 2"))

  df_medians <- df_long |>
    group_by(measure, time) |>
    summarise(n = n(), median = median(value), .groups = "drop") |>
    mutate(label = sprintf("n = %d\nmedian = %.0f%%", n, 100 * median))

  p <- ggplot(df_long, aes(x = value)) +
    geom_dots(layout = "bin", binwidth = 0.02, overflow = "compress", fill = "#4477AA", colour = "#4477AA", alpha = 0.7) +
    geom_vline(data = df_medians, aes(xintercept = median), colour = "#EE6677", linewidth = 0.8) +
    geom_text(data = df_medians, aes(x = 1, y = 0.95, label = label),
              hjust = 1, vjust = 1, size = 3.2, inherit.aes = FALSE) +
    facet_grid(measure ~ time) +
    scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25), labels = scales::percent) +
    scale_y_continuous(breaks = NULL) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), strip.text = element_text(face = "bold"),
          panel.spacing = unit(1, "lines")) +
    labs(x = x_label, y = NULL)

  ggsave(file.path(output_choice_stay_dir, paste0(plot_name, ".pdf")), plot = p, width = 10, height = 8, bg = "white")
  ggsave(file.path(output_choice_stay_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 8, dpi = 300, bg = "white")
  p
}

p_choice_share <- plot_measures(c("share_a", "share_b", "share_neither"),
                                "percentage of the participant's trials", "choice_share_dot_histograms")

p_stay_rate <- plot_measures(c("stay_neither", "stay_a", "stay_b", "stay_key"),
                             "percentage of times the same response followed on the next trial",
                             "stay_rate_dot_histograms")
