#### PLOT POSTERIOR PREDICTIVE CHECKS ####

stat_labels <- c(skip_rate   = "Skip rate",
                 left_share  = "Share of answered trials on the left key",
                 key_repeat  = "Key repetition (consecutive answered trials)",
                 longest_run = "Longest run of identical responses",
                 viol_rate   = "Transitivity violation rate")

# Observed against the simulated median and 90% band, one point per participant-session
pdf(file.path(output_dir, "ppc_observed_vs_simulated.pdf"), width = 12, height = 5)
for (st in stat_names) {
  p <- df_ppc |>
    filter(statistic == st) |>
    ggplot(aes(x = observed, y = sim_median, colour = outside)) +
    geom_abline(slope = 1, intercept = 0, colour = "grey50") +
    geom_linerange(aes(ymin = sim_q05, ymax = sim_q95), alpha = 0.35, linewidth = 0.3) +
    geom_point(size = 0.7, alpha = 0.7) +
    scale_colour_manual(values = c(`FALSE` = "grey40", `TRUE` = "#c0392b"),
                        labels = c(`FALSE` = "inside 90% band", `TRUE` = "outside 90% band"), name = NULL) +
    facet_wrap(~ model) +
    labs(title = stat_labels[[st]], x = "Observed", y = "Simulated (median and 90% band)") +
    theme_bw() +
    theme(legend.position = "bottom")
  print(p)
}
dev.off()

# Posterior predictive p-values: roughly uniform if the model is adequate
pdf(file.path(output_dir, "ppc_pvalue_distributions.pdf"), width = 12, height = 8)
p_ppp <- df_ppc |>
  ggplot(aes(x = ppp)) +
  geom_histogram(breaks = seq(0, 1, 0.1), fill = "grey60", colour = "white") +
  facet_grid(statistic ~ model, labeller = labeller(statistic = stat_labels, .default = label_value), scales = "free_y") +
  labs(x = "Posterior predictive p-value (mid-p)", y = "Participant-sessions") +
  theme_bw() +
  theme(strip.text.y = element_text(size = 6))
print(p_ppp)
dev.off()

# Share outside the 90% band per statistic and model (about 10% expected)
p_share <- df_summary |>
  filter(subgroup == "all sessions") |>
  ggplot(aes(x = statistic, y = share_outside, fill = model)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_hline(yintercept = 0.10, linetype = "dashed") +
  scale_x_discrete(labels = stat_labels) +
  labs(x = NULL, y = "Share of sessions outside 90% band", fill = NULL) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1), legend.position = "bottom")
ggsave(file.path(output_dir, "ppc_share_outside.png"), p_share, width = 9, height = 5, dpi = 150)
ggsave(file.path(output_dir, "ppc_share_outside.pdf"), p_share, width = 9, height = 5)
