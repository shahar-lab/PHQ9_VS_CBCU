#### PLOT BETA VS CHOICE PREDICTION, PER SESSION ####
# reads:  artifacts/beta_posterior_width.csv (plot_beta_posterior_width.R: beta median, 95% HDI),
#         artifacts/choice_prediction_by_wave.csv (prep_choice_prediction.R: choice prediction
#         median, 95% HDI; every participant per day)
# writes: output/relations between parameters/beta_vs_choice_prediction_time1.{pdf,png},
#                                              beta_vs_choice_prediction_time2.{pdf,png}
#
# Is a participant with a higher beta (less choice noise) also better predicted by the model?
# Dot = posterior medians; horizontal whisker = 95% HDI of beta, vertical = 95% HDI of choice
# prediction. Different-scale comparison (beta ~0-20 vs a probability): no coord_equal() and
# no y = x line (as in plot_phq9_parameter_scatter.R); a square panel keeps the axes the same
# visual length. Beta axis starts at its bound, 0.

df_beta_wave <- read_csv(file.path(artifacts_dir, "beta_posterior_width.csv"), show_col_types = FALSE) |>
  select(id = prolific_id, day = time, beta = beta_median,
         beta_lower = hdi_lower, beta_upper = hdi_upper)

df_cp_wave <- read_csv(file.path(artifacts_dir, "choice_prediction_by_wave.csv"), show_col_types = FALSE) |>
  select(id, day, cp, cp_lower = hdi_lower, cp_upper = hdi_upper)

df_beta_cp <- inner_join(df_beta_wave, df_cp_wave, by = c("id", "day"))
stopifnot(nrow(df_beta_cp) == nrow(df_cp_wave))   # every participant x day has a beta

# Same axis limits in both sessions, wide enough for every whisker
beta_limits <- c(0, max(df_beta_cp$beta_upper))                                # beta > 0: start at 0
cp_limits   <- c(min(df_beta_cp$cp_lower), min(max(df_beta_cp$cp_upper), 1))   # a probability: never past 1

plot_beta_vs_cp <- function(wave, wave_label) {

  df_wave   <- filter(df_beta_cp, day == wave)
  pearson_r <- cor(df_wave$beta, df_wave$cp)

  p <- ggplot(df_wave, aes(x = beta, y = cp)) +
    geom_errorbar(aes(xmin = beta_lower, xmax = beta_upper), orientation = "y", width = 0,
                  colour = "#4477AA", alpha = 0.25, linewidth = 0.4) +
    geom_errorbar(aes(ymin = cp_lower, ymax = cp_upper), width = 0,
                  colour = "#4477AA", alpha = 0.25, linewidth = 0.4) +
    geom_point(colour = "#4477AA", alpha = 0.9, size = 2) +
    geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
    annotate("text", x = Inf, y = -Inf,
             label = sprintf("[Pearson r of medians = %.2f]", pearson_r),
             hjust = 1.05, vjust = -1, size = 3.5, colour = "grey30") +
    scale_x_continuous(breaks = scales::breaks_pretty(n = 6)) +
    scale_y_continuous(breaks = scales::breaks_pretty(n = 6)) +
    coord_cartesian(xlim = beta_limits, ylim = cp_limits) +   # zooms without dropping data
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank(), aspect.ratio = 1) +
    labs(title = wave_label,
         x = "Beta (posterior median, 95% HDI)",
         y = "Choice prediction (posterior median, 95% HDI)",
         caption = sprintf(paste("%d participants. Choice prediction: mean P(chosen option) over the session's trials.",
                                 "Whiskers: 95%% HDI."), nrow(df_wave)))

  plot_name <- paste0("beta_vs_choice_prediction_", wave)
  ggsave(file.path(output_relations_dir, paste0(plot_name, ".pdf")),
         plot = p, width = 10, height = 8, bg = "white")
  ggsave(file.path(output_relations_dir, paste0(plot_name, ".png")),
         plot = p, width = 10, height = 8, dpi = 300, bg = "white")

  p
}

p_beta_vs_cp_time1 <- plot_beta_vs_cp("time1", "Time 1")
p_beta_vs_cp_time2 <- plot_beta_vs_cp("time2", "Time 2")
