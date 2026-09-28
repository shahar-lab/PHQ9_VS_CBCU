#### PLOT MU_ AND SIGMA_ POSTERIORS SEPARATELY ####
# Reuses plot_df/stats_df/anchor_df already built by prep_group_posterior.R,
# split into the 4 mu_ panels and the 4 sigma_ panels -- the existing combined
# 8-panel group_recovery.pdf (all mu_ and sigma_ together) is untouched.

mu_vars    <- group_vars[str_starts(group_vars, "mu_")]
sigma_vars <- group_vars[str_starts(group_vars, "sigma_")]

# Matches plot_group_recovery.R's facet-strip relabelling: key_decay is
# referred to as gamma in this lab's figures.
gamma_labeller <- as_labeller(c(
  mu_log_beta         = "mu_log_beta",
  sigma_log_beta      = "sigma_log_beta",
  mu_tau              = "mu_tau",
  sigma_tau           = "sigma_tau",
  mu_logit_key_decay  = "mu_logit_gamma",
  sigma_key_decay     = "sigma_gamma",
  mu_rho              = "mu_rho",
  sigma_rho           = "sigma_rho"
))

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
    facet_wrap(~variable, scales = "free_x", labeller = gamma_labeller) +
    scale_colour_manual(values = c(
      "True value"                   = "#EE6677",
      "Posterior median"             = "grey65",
      "Sample statistic (subjects)"  = "#4477AA"
    )) +
    theme_minimal(base_size = 13) +
    theme(
      panel.grid           = element_blank(),
      axis.title.y         = element_blank(),
      axis.text.y          = element_blank(),
      axis.ticks.y         = element_blank(),
      axis.line.y          = element_blank(),
      axis.line.x          = element_line(colour = "grey30"),
      legend.position      = "bottom",
      legend.background    = element_blank(),
      legend.key           = element_blank()
    ) +
    labs(x = "Posterior value", colour = NULL) +
    coord_cartesian(clip = "off")
}

p_mu_posteriors    <- plot_group_posterior_subset(mu_vars)
p_sigma_posteriors <- plot_group_posterior_subset(sigma_vars)

ggsave(file.path(output_dir, "mu_posteriors.pdf"), plot = p_mu_posteriors, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "mu_posteriors.png"), plot = p_mu_posteriors, width = 10, height = 8, dpi = 300, bg = "white")

ggsave(file.path(output_dir, "sigma_posteriors.pdf"), plot = p_sigma_posteriors, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "sigma_posteriors.png"), plot = p_sigma_posteriors, width = 10, height = 8, dpi = 300, bg = "white")
