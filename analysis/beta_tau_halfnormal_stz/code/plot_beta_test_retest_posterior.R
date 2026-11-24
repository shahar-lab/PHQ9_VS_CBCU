#### PLOT BETA TEST-RETEST: TIME 2 POSTERIOR VS TIME 1 MEDIAN ####
# reads: artifacts/beta_draws_by_wave.rds if it exists, otherwise fit_list (from
#        fit_model.R; read from artifacts/fit_<wave>.rds if not in memory) and
#        artifacts/subject_lookup_<wave>.csv
# writes: output/test-retest across sessions/correlation/beta_test_retest_posterior_scatter.png,
#         artifacts/beta_draws_by_wave.rds
#
# A version of beta_test_retest_scatter.png that shows the time 2 posterior instead of
# the time 2 median. Each participant sits at their time 1 posterior median on the x axis;
# above it, a vertical violin shows the full time 2 posterior of beta (density of all
# draws), with the time 2 median as a dot. Two panels, split at beta_threshold_time1:
#   A: participants with time 1 median above the threshold
#   B: participants with time 1 median below the threshold
# Both panels share the y axis. Both axes are logarithmic, as in beta_tau_lognormal_stz,
# so the plots can be compared across models (beta > 0, so the log axis is defined).

beta_threshold_time1 <- 7
violin_half_width    <- 0.012   # widest point of each violin, in log10 units of the x axis
tail_trim            <- 0.005   # violins drawn between the 0.5% and 99.5% posterior quantiles

beta_draws_path <- file.path(artifacts_dir, "beta_draws_by_wave.rds")

if (file.exists(beta_draws_path)) {
  beta_draws_by_wave <- readRDS(beta_draws_path)
} else {
  if (!exists("fit_list")) {
    fit_list <- map(set_names(waves), \(wave) readRDS(file.path(artifacts_dir, paste0("fit_", wave, ".rds"))))
  }
  # One matrix per wave: rows = posterior draws, columns = participants (prolific_id)
  beta_draws_by_wave <- map(set_names(waves), \(wave) {
    draws  <- fit_list[[wave]]$draws("beta", format = "draws_matrix")
    lookup <- read_csv(file.path(artifacts_dir, paste0("subject_lookup_", wave, ".csv")), show_col_types = FALSE)
    draws_wave <- matrix(as.numeric(draws), nrow = nrow(draws), dimnames = list(NULL, colnames(draws)))
    draws_wave <- draws_wave[, sprintf("beta[%d]", lookup$subject_index)]
    colnames(draws_wave) <- lookup$prolific_id
    draws_wave
  })
  saveRDS(beta_draws_by_wave, beta_draws_path)
}

# Participants with both waves
shared_ids <- intersect(colnames(beta_draws_by_wave$time1), colnames(beta_draws_by_wave$time2))

df_beta_medians <- tibble(
  prolific_id  = shared_ids,
  median_time1 = apply(beta_draws_by_wave$time1[, shared_ids], 2, median),
  median_time2 = apply(beta_draws_by_wave$time2[, shared_ids], 2, median)
)

# One violin per participant: density of log10(time 2 draws), mirrored around the
# participant's time 1 median (on the log10 x scale)
df_violins <- df_beta_medians |>
  mutate(outline = map2(prolific_id, median_time1, \(id, x_center) {
    log_draws <- log10(beta_draws_by_wave$time2[, id])
    dens      <- density(log_draws, n = 256,
                         from = quantile(log_draws, tail_trim), to = quantile(log_draws, 1 - tail_trim))
    half      <- violin_half_width * dens$y / max(dens$y)
    tibble(x = c(x_center * 10^(-half), rev(x_center * 10^half)),
           y = 10^c(dens$x, rev(dens$x)))
  })) |>
  select(prolific_id, median_time1, outline) |>
  unnest(outline)

# Same y range in both panels, so they can be compared
shared_y_limits <- range(c(df_violins$y, df_beta_medians$median_time2))
log_axis_breaks <- c(0.5, 1, 2, 5, 10, 20, 50, 100, 200)

plot_time2_posterior <- function(keep, group_label, x_breaks) {
  medians <- filter(df_beta_medians, keep(median_time1))
  violins <- filter(df_violins, keep(median_time1))
  r_log   <- cor(log(medians$median_time1), log(medians$median_time2))

  ggplot() +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60") +
    geom_polygon(data = violins, aes(x = x, y = y, group = prolific_id),
                 fill = "#4477AA", colour = "#4477AA", alpha = 0.25, linewidth = 0.15) +
    geom_point(data = medians, aes(x = median_time1, y = median_time2),
               colour = "grey15", size = 1.2) +
    annotate(
      "text",
      x = Inf, y = Inf,
      label = sprintf("[%d participants with time 1 beta %s]\n[Pearson r of log medians = %.2f]",
                      nrow(medians), group_label, r_log),
      hjust = 1.05, vjust = 1.2,
      size = 3.5, colour = "grey30"
    ) +
    scale_x_log10(breaks = x_breaks, labels = as.character(x_breaks)) +
    scale_y_log10(breaks = log_axis_breaks, labels = as.character(log_axis_breaks)) +
    coord_cartesian(ylim = shared_y_limits) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = "Time 1 beta, posterior median (log axis)",
         y = "Time 2 beta, posterior (log axis)")
}

p_beta_posterior_above <- plot_time2_posterior(\(x) x > beta_threshold_time1,
                                               sprintf("> %g", beta_threshold_time1),
                                               c(7, 8, 10, 12, 15, 20))
p_beta_posterior_below <- plot_time2_posterior(\(x) x <= beta_threshold_time1,
                                               sprintf("<= %g", beta_threshold_time1),
                                               c(1, 1.5, 2, 3, 4, 5, 7))

p_beta_retest_posterior <- (p_beta_posterior_above | p_beta_posterior_below) +
  plot_annotation(
    tag_levels = "A",
    caption = sprintf("Violins: full time 2 posterior of each participant (%.1f%%-%.1f%% quantiles). Dots: time 2 posterior median. Dashed: time 1 = time 2.",
                      100 * tail_trim, 100 * (1 - tail_trim))
  )

ggsave(
  file.path(output_retest_corr_dir, "beta_test_retest_posterior_scatter.png"),
  plot = p_beta_retest_posterior,
  width = 18, height = 8, dpi = 300, bg = "white"
)
