#### PLOT MU_ AND SIGMA_ POSTERIORS SEPARATELY ####
# reads: artifacts/group_plot_data.rds
# writes: output/15_mu_posteriors.{pdf,png}, 15_sigma_posteriors.{pdf,png}, artifacts/p_mu_posteriors.rds, p_sigma_posteriors.rds

group_plot_data <- readRDS(file.path(artifacts_dir, "group_plot_data.rds"))
group_vars <- group_plot_data$group_vars
plot_df    <- group_plot_data$plot_df
stats_df   <- group_plot_data$stats_df
anchor_df  <- group_plot_data$anchor_df

mu_vars    <- group_vars[str_starts(group_vars, "mu_")]
sigma_vars <- group_vars[str_starts(group_vars, "sigma_")]

plot_group_posterior_subset <- function(vars_subset) {
  plot_df_subset   <- plot_df   |> filter(variable %in% vars_subset) |> mutate(variable = factor(variable, levels = vars_subset))
  stats_df_subset  <- stats_df  |> filter(variable %in% vars_subset) |> mutate(variable = factor(variable, levels = vars_subset))
  anchor_df_subset <- anchor_df |> filter(variable %in% vars_subset) |> mutate(variable = factor(variable, levels = vars_subset))

  ggplot(plot_df_subset, aes(x = value, y = 0)) +
    stat_slab(fill = "gray80") +
    stat_pointinterval(
      aes(linewidth = after_stat(-.width)),
      .width     = c(0.80, 0.90),
      point_size = 3
    ) +
    scale_linewidth_continuous(range = c(1, 2), guide = "none") +
    geom_vline(
      data = stats_df_subset, aes(xintercept = true_value, colour = "True value"),
      linetype = "dashed", linewidth = 0.7
    ) +
    geom_vline(
      data = stats_df_subset, aes(xintercept = med_val, colour = "Posterior median"),
      linetype = "dashed", linewidth = 0.4
    ) +
    geom_vline(
      data = stats_df_subset, aes(xintercept = sample_stat, colour = "Sample statistic (subjects)"),
      linetype = "dashed", linewidth = 0.4
    ) +
    geom_text(
      data = stats_df_subset,
      aes(x = med_val, y = Inf,
          label = sprintf("[median = %.2f, pd = %.2f%%]", med_val, pd_val)),
      inherit.aes = FALSE, hjust = -0.05, vjust = 1.4, size = 3, colour = "grey40"
    ) +
    geom_blank(data = anchor_df_subset, aes(x = value, y = 0)) +
    facet_wrap(~variable, scales = "free_x") +
    scale_colour_manual(values = c(
      "True value"                   = "#EE6677",
      "Posterior median"             = "grey65",
      "Sample statistic (subjects)"  = "#4477AA"
    )) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid        = element_blank(),
      axis.title.y      = element_blank(),
      axis.text.y       = element_blank(),
      axis.ticks.y      = element_blank(),
      axis.line.y       = element_blank(),
      axis.line.x       = element_line(colour = "grey30"),
      legend.position   = "bottom",
      legend.background = element_blank(),
      legend.key        = element_blank()
    ) +
    labs(x = "Posterior value", colour = NULL) +
    coord_cartesian(clip = "off")
}

p_mu_posteriors    <- plot_group_posterior_subset(mu_vars)
p_sigma_posteriors <- plot_group_posterior_subset(sigma_vars)

ggsave(file.path(output_dir, "15_mu_posteriors.pdf"), plot = p_mu_posteriors, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "15_mu_posteriors.png"), plot = p_mu_posteriors, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "15_sigma_posteriors.pdf"), plot = p_sigma_posteriors, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "15_sigma_posteriors.png"), plot = p_sigma_posteriors, width = 10, height = 8, dpi = 300, bg = "white")

saveRDS(p_mu_posteriors, file.path(artifacts_dir, "p_mu_posteriors.rds"))
saveRDS(p_sigma_posteriors, file.path(artifacts_dir, "p_sigma_posteriors.rds"))
