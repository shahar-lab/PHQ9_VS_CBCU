#### HISTOGRAMS OF PER-PARTICIPANT ACCURACY, ONE PER MODEL ####
# Each participant contributes one value: the mean of their posterior predictive accuracy distribution
# (both sessions pooled). Dashed line: chance (1/3, three possible responses). Solid line: median
# participant. A second page shows the best-guess accuracy.

acc_breaks <- seq(0, 1, by = 0.025)

plot_accuracy_hist <- function(df, value_col, model_name, x_label) {
  vals <- df[[value_col]]
  med  <- median(vals)
  ggplot(df, aes(x = .data[[value_col]])) +
    geom_histogram(breaks = acc_breaks, fill = model_colors[[model_name]], colour = "white", linewidth = 0.5) +
    geom_vline(xintercept = 1 / 3, linetype = "dashed", colour = "grey45") +
    geom_vline(xintercept = med, colour = "grey15", linewidth = 0.6) +
    annotate("text", x = med, y = Inf, vjust = 1.5, hjust = -0.05, size = 3.2, colour = "grey15",
             label = sprintf("median = %.1f%%", 100 * med)) +
    annotate("text", x = 1 / 3, y = Inf, vjust = 1.5, hjust = 1.05, size = 3, colour = "grey45", label = "chance") +
    scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 1)) +
    labs(title = model_name,
         subtitle = sprintf("%d participants, both sessions pooled (up to 210 trials each)", nrow(df)),
         x = x_label, y = "Participants") +
    theme_bw() +
    theme(panel.grid.minor = element_blank())
}

label_ppa  <- "Posterior predictive accuracy (mean over 1000 draws): % of trials where the predicted response = the observed response"
label_best <- "Best-guess accuracy: % of trials where the most probable response = the observed response"

for (m in model_labels) {
  df_m <- filter(df_accuracy_participant, model == m)
  p_ppa  <- plot_accuracy_hist(df_m, "ppa_mean", m, label_ppa)
  p_best <- plot_accuracy_hist(df_m, "best_guess_acc", m, label_best)

  pdf(file.path(output_dir, paste0("accuracy_histogram_", m, ".pdf")), width = 9, height = 5)
  print(p_ppa)
  print(p_best)
  dev.off()
  ggsave(file.path(output_dir, paste0("accuracy_histogram_", m, ".png")), p_ppa, width = 9, height = 5, dpi = 150)
}

# Posterior predictive distribution of the GROUP mean accuracy (one value per draw), both models
p_group <- df_group_draws |>
  ggplot(aes(x = group_mean, fill = model)) +
  geom_histogram(bins = 60, colour = "white", linewidth = 0.2, position = "identity", alpha = 0.85) +
  scale_fill_manual(values = model_colors, name = NULL) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 0.1)) +
  labs(title = "Posterior predictive distribution of the mean accuracy across participants",
       subtitle = "One value per posterior draw (1000 draws per model)",
       x = "Mean accuracy across participants", y = "Draws") +
  theme_bw() +
  theme(legend.position = "top", panel.grid.minor = element_blank())
ggsave(file.path(output_dir, "accuracy_group_mean_distribution.pdf"), p_group, width = 9, height = 5)
