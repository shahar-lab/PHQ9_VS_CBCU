#### PLOT GROUP-LEVEL POSTERIOR RECOVERY ####

p_group <- ggplot(plot_df, aes(x = value, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(
    aes(linewidth = after_stat(-.width)),
    .width     = c(0.80, 0.90),
    point_size = 3
  ) +
  scale_linewidth_continuous(range = c(1, 2), guide = "none") +
  geom_vline(
    data = stats_df, aes(xintercept = true_value, colour = "True value"),
    linetype = "dashed", linewidth = 0.7
  ) +
  geom_vline(
    data = stats_df, aes(xintercept = med_val, colour = "Posterior median"),
    linetype = "dashed", linewidth = 0.4
  ) +
  geom_text(
    data = stats_df,
    aes(x = med_val, y = Inf,
        label = sprintf("[median = %.2f, pd = %.2f%%]", med_val, pd_val)),
    inherit.aes = FALSE, hjust = -0.05, vjust = 1.4, size = 3, colour = "grey40"
  ) +
  geom_blank(data = anchor_df, aes(x = value, y = 0)) +
  facet_wrap(~variable, scales = "free_x") +
  scale_colour_manual(values = c("True value" = "#EE6677", "Posterior median" = "grey65")) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid           = element_blank(),
    axis.title.y         = element_blank(),
    axis.text.y          = element_blank(),
    axis.ticks.y         = element_blank(),
    axis.line.y          = element_blank(),
    axis.line.x          = element_line(colour = "grey30"),
    legend.position      = c(1, 0.95),
    legend.justification = c("right", "top"),
    legend.background    = element_blank(),
    legend.key           = element_blank()
  ) +
  labs(x = "Posterior value", colour = NULL) +
  coord_cartesian(clip = "off")

ggsave(file.path(output_dir, "group_recovery.pdf"), plot = p_group, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "group_recovery.png"), plot = p_group, width = 10, height = 8, dpi = 300, bg = "white")
