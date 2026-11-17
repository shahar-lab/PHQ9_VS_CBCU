#### PLOT UTILITY RECOVERY FOR SUBJECTS WITH EXTREME BETA OR TAU ####
# reads: artifacts/recovered_parameters.rds, true_parameters.rds, simulated_data.rds
# writes: output/11_u_recovery_by_beta, 11_u_recovery_by_tau, 11_u_recovery_by_beta_groups,
#         11_u_recovery_by_tau_groups (each .pdf/.png), artifacts/p_u_recovery_by_*.rds,
#         u_recovery_by_subject.rds
#
# The utility scatter (06_u_recovery) split by the subject's TRUE beta or tau, two ways:
#   by_beta, by_tau:               lowest extreme_quantile of subjects, middle, highest extreme_quantile
#   by_beta_groups, by_tau_groups: n_quantile_groups equal-sized groups (10 = deciles)
# Points are coloured by the subject's share of "None" choices: a subject who always
# chooses None gives no information about u, so all 15 utilities are recovered near the
# prior mean of 0 and show up as a horizontal row.

recovered_parameters <- readRDS(file.path(artifacts_dir, "recovered_parameters.rds"))
true_parameters      <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
simulated_data       <- readRDS(file.path(artifacts_dir, "simulated_data.rds"))

# One row per subject: true beta and tau, share of None choices, utility recovery
u_recovery_by_subject <- recovered_parameters |>
  filter(parameter == "u") |>
  group_by(subject) |>
  summarise(r_u = cor(true_value, recovered_value), sd_recovered_u = sd(recovered_value), .groups = "drop") |>
  left_join(simulated_data |> group_by(subject) |> summarise(p_none = mean(choice == "None")), by = "subject") |>
  left_join(true_parameters |> select(subject, beta, tau), by = "subject")

u_df <- recovered_parameters |>
  filter(parameter == "u") |>
  left_join(u_recovery_by_subject, by = "subject")

# Same axes in every panel, so the groups can be compared
shared_limits <- range(c(u_df$true_value, u_df$recovered_value))

# Splits subjects into low / middle / high by the true value of split_param
plot_u_by_extremes <- function(split_param, param_label) {
  cut_low  <- quantile(true_parameters[[split_param]], extreme_quantile)
  cut_high <- quantile(true_parameters[[split_param]], 1 - extreme_quantile)
  group_labels <- c(
    sprintf("Low %s (bottom %d%%: %s <= %.2f)", param_label, round(100 * extreme_quantile), param_label, cut_low),
    sprintf("Middle %d%%", round(100 * (1 - 2 * extreme_quantile))),
    sprintf("High %s (top %d%%: %s >= %.2f)", param_label, round(100 * extreme_quantile), param_label, cut_high)
  )

  plot_df <- u_df |>
    mutate(group = case_when(
      .data[[split_param]] <= cut_low  ~ group_labels[1],
      .data[[split_param]] >= cut_high ~ group_labels[3],
      TRUE                             ~ group_labels[2]
    ),
    group = factor(group, levels = group_labels))

  stats_df <- plot_df |>
    group_by(group) |>
    summarise(label = sprintf("[Pearson r = %.2f, %d subjects]", cor(true_value, recovered_value), n_distinct(subject)),
              .groups = "drop")

  ggplot(plot_df, aes(x = true_value, y = recovered_value, colour = p_none)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
    geom_point(alpha = 0.75, size = 2) +
    geom_smooth(aes(group = 1), method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_text(data = stats_df, aes(x = Inf, y = Inf, label = label), inherit.aes = FALSE,
              hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
    facet_wrap(~group) +
    scale_colour_viridis_c(limits = c(0, 1), name = "Share of\n\"None\" choices") +
    coord_equal(xlim = shared_limits, ylim = shared_limits) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = "True utility (u)", y = "Recovered utility (u)",
         title = sprintf("Utility recovery by true %s", param_label))
}

# Splits subjects into n_quantile_groups equal-sized groups by the true value of split_param
# (10 = deciles), one panel per group, lowest to highest
plot_u_by_quantile_groups <- function(split_param, param_label) {
  subject_groups <- true_parameters |>
    mutate(group_index = ntile(.data[[split_param]], n_quantile_groups)) |>
    group_by(group_index) |>
    mutate(group = sprintf("Group %d: %s %.2f to %.2f", group_index, param_label,
                           min(.data[[split_param]]), max(.data[[split_param]]))) |>
    ungroup() |>
    select(subject, group_index, group)

  plot_df <- u_df |>
    left_join(subject_groups, by = "subject") |>
    mutate(group = fct_reorder(group, group_index))

  stats_df <- plot_df |>
    group_by(group) |>
    summarise(label = sprintf("[r = %.2f, None = %.0f%%]", cor(true_value, recovered_value),
                              100 * mean(p_none[!duplicated(subject)])),
              .groups = "drop")

  ggplot(plot_df, aes(x = true_value, y = recovered_value, colour = p_none)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
    geom_point(alpha = 0.75, size = 1.5) +
    geom_smooth(aes(group = 1), method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    geom_text(data = stats_df, aes(x = Inf, y = -Inf, label = label), inherit.aes = FALSE,
              hjust = 1.05, vjust = -0.6, size = 3, colour = "grey30") +
    facet_wrap(~group, nrow = 2) +
    scale_colour_viridis_c(limits = c(0, 1), name = "Share of\n\"None\" choices") +
    coord_equal(xlim = shared_limits, ylim = shared_limits) +
    theme_minimal(base_size = 12) +
    theme(panel.grid.minor = element_blank(), strip.text = element_text(size = 10)) +
    labs(x = "True utility (u)", y = "Recovered utility (u)",
         title = sprintf("Utility recovery by true %s: %d groups of %d subjects (r and mean share of None per group)",
                         param_label, n_quantile_groups, n_subjects / n_quantile_groups))
}

recovery_split_plots <- list(
  by_beta        = list(plot = plot_u_by_extremes("beta", "beta"),               width = 16, height = 6.5),
  by_tau         = list(plot = plot_u_by_extremes("tau", "tau"),                 width = 16, height = 6.5),
  by_beta_groups = list(plot = plot_u_by_quantile_groups("beta", "beta"),        width = 20, height = 9.5),
  by_tau_groups  = list(plot = plot_u_by_quantile_groups("tau", "tau"),          width = 20, height = 9.5)
)

for (name in names(recovery_split_plots)) {
  spec <- recovery_split_plots[[name]]
  file_stem <- file.path(output_dir, paste0("11_u_recovery_", name))
  ggsave(paste0(file_stem, ".pdf"), plot = spec$plot, width = spec$width, height = spec$height, bg = "white")
  ggsave(paste0(file_stem, ".png"), plot = spec$plot, width = spec$width, height = spec$height, dpi = 300, bg = "white")
  saveRDS(spec$plot, file.path(artifacts_dir, paste0("p_u_recovery_", name, ".rds")))
}

saveRDS(u_recovery_by_subject, file.path(artifacts_dir, "u_recovery_by_subject.rds"))
