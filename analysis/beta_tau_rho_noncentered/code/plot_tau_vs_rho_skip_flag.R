#### PLOT TAU VS RHO, FLAGGING SKIP-HEAVY PARTICIPANTS ####
# Same tau-vs-rho scatter as plot_cross_parameter_scatter.R, with participants whose
# choices in that session were skip (None) on at least skip_flag_threshold of trials
# drawn in a second colour. Pearson r is reported with and without them. tau and rho
# are on different scales, so no coord_equal() and no y = x line.

df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

# proportion of skip choices per participant per session, out of all trials
df_skip_prop <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE) |>
  group_by(prolific_id, time) |>
  summarise(skip_prop = mean(choice == "skip"), .groups = "drop") |>
  mutate(skip_flag = skip_prop >= skip_flag_threshold)

df_tau_rho_skip <- df_participant_parameters |>
  select(prolific_id, time, tau, rho) |>
  left_join(df_skip_prop, by = c("prolific_id", "time"))

write_csv(df_tau_rho_skip, file.path(artifacts_dir, "tau_rho_skip_flag.csv"))

plot_tau_vs_rho_skip_flag <- function(df, wave, plot_name) {

  df_wave <- df |>
    filter(time == wave, !is.na(tau), !is.na(rho)) |>
    mutate(group = if_else(skip_flag, sprintf("Skip on >= %.0f%% of trials", 100 * skip_flag_threshold), "Other participants"))

  pearson_r_all       <- cor(df_wave$tau, df_wave$rho, method = "pearson")
  pearson_r_unflagged <- with(filter(df_wave, !skip_flag), cor(tau, rho, method = "pearson"))
  n_flagged           <- sum(df_wave$skip_flag)

  p <- ggplot(df_wave, aes(x = tau, y = rho)) +
    geom_point(aes(colour = group), alpha = 0.75, size = 2) +
    geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    annotate(
      "text",
      x = Inf, y = Inf,
      label = sprintf("[Pearson r = %.2f, all]\n[Pearson r = %.2f, without the %d flagged]",
                      pearson_r_all, pearson_r_unflagged, n_flagged),
      hjust = 1.05, vjust = 1.2,
      size = 3.5, colour = "grey30"
    ) +
    scale_colour_manual(values = c("#4477AA", "#228833"), breaks = c("Other participants", unique(df_wave$group[df_wave$skip_flag])), name = NULL) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), legend.position = "bottom") +
    labs(x = "tau", y = "rho", title = wave)

  ggsave(file.path(output_relations_dir, paste0(plot_name, ".pdf")), plot = p, width = 10, height = 8, bg = "white")
  ggsave(file.path(output_relations_dir, paste0(plot_name, ".png")), plot = p, width = 10, height = 8, dpi = 300, bg = "white")

  p
}

p_tau_vs_rho_skip_flag_time1 <- plot_tau_vs_rho_skip_flag(df_tau_rho_skip, "time1", "tau_vs_rho_skip_flag_time1")
p_tau_vs_rho_skip_flag_time2 <- plot_tau_vs_rho_skip_flag(df_tau_rho_skip, "time2", "tau_vs_rho_skip_flag_time2")
