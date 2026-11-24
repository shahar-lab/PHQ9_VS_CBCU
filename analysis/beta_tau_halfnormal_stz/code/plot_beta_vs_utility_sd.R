#### PLOT BETA VS SD OF THE POINTWISE UTILITY VECTOR, PER SESSION ####
# reads:  artifacts/participant_parameters.csv (summarise_posterior.R: posterior median of each
#         of the 15 utilities u_1..u_15 and of beta, per participant x session)
# writes: artifacts/utility_pointwise_sd.csv (pointwise utilities, their SD, beta),
#         output/relations between parameters/beta_vs_utility_sd_time1.{pdf,png},
#                                              beta_vs_utility_sd_time2.{pdf,png}
#
# Pointwise utility = posterior median of each u[i]. Per participant x session, utility SD = SD of
# those 15 medians: how strongly the participant separates the options. In the model, the logits
# are beta * u, with u sum-to-zero and its scale set only by the prior (u ~ normal(0, u_prior_sd)),
# so beta and the spread of u can trade off against each other.
# Different scales: no coord_equal() and no y = x line (as in plot_phq9_parameter_scatter.R); a
# square panel keeps the axes the same visual length. Both axes start at their bound, 0.

df_utility_sd <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE) |>
  select(id = prolific_id, day = time, u_1:u_15, beta) |>
  mutate(u_sd = apply(pick(u_1:u_15), 1, sd))

stopifnot(!anyNA(df_utility_sd$u_sd), !anyNA(df_utility_sd$beta))
write_csv(df_utility_sd, file.path(artifacts_dir, "utility_pointwise_sd.csv"))

# Same axis limits in both sessions
beta_limits <- c(0, max(df_utility_sd$beta) * 1.05)
u_sd_limits <- c(0, max(df_utility_sd$u_sd) * 1.05)

plot_beta_vs_u_sd <- function(wave, wave_label) {

  df_wave   <- filter(df_utility_sd, day == wave)
  pearson_r <- cor(df_wave$beta, df_wave$u_sd)

  p <- ggplot(df_wave, aes(x = beta, y = u_sd)) +
    geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
    geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    annotate("text", x = Inf, y = Inf,
             label = sprintf("[Pearson r = %.2f]", pearson_r),
             hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
    scale_x_continuous(breaks = scales::breaks_pretty(n = 6), expand = expansion(mult = c(0, 0.02))) +
    scale_y_continuous(breaks = scales::breaks_pretty(n = 6), expand = expansion(mult = c(0, 0.02))) +
    coord_cartesian(xlim = beta_limits, ylim = u_sd_limits) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), aspect.ratio = 1) +
    labs(title = wave_label,
         x = "Beta (posterior median)",
         y = "SD of the 15 utilities (posterior medians)",
         caption = sprintf("%d participants. Each dot: one participant's beta and the SD of their pointwise utility vector.",
                           nrow(df_wave)))

  plot_name <- paste0("beta_vs_utility_sd_", wave)
  ggsave(file.path(output_relations_dir, paste0(plot_name, ".pdf")),
         plot = p, width = 10, height = 8, bg = "white")
  ggsave(file.path(output_relations_dir, paste0(plot_name, ".png")),
         plot = p, width = 10, height = 8, dpi = 300, bg = "white")

  p
}

p_beta_vs_u_sd_time1 <- plot_beta_vs_u_sd("time1", "Time 1")
p_beta_vs_u_sd_time2 <- plot_beta_vs_u_sd("time2", "Time 2")
