#### PLOT BETA POSTERIOR WIDTH VS BETA ####
# reads: artifacts/beta_draws_by_wave.rds (written by plot_beta_test_retest_posterior.R)
# writes: output/beta_posterior_width.png, artifacts/beta_posterior_width.csv
#
# Question: is the posterior of beta wider for participants with a high beta?
# Per participant and wave: posterior median of beta and the width of its 95% HDI.
#   A: width in beta units (upper - lower)
#   B: width on the log scale (HDI of log(beta): log(upper) - log(lower)), i.e. relative
#      width. On this scale a width of 1 means the upper bound is e = 2.7 times the lower.
# A can grow with beta even if the relative uncertainty stays the same;
# B shows whether high-beta participants are also less precisely measured in relative terms.

hdi_prob <- 0.95

# Shortest interval containing hdi_prob of the draws
hdi_bounds <- function(x, prob) {
  x       <- sort(x)
  n_in    <- ceiling(prob * length(x))
  widths  <- x[n_in:length(x)] - x[1:(length(x) - n_in + 1)]
  i_start <- which.min(widths)
  c(lower = x[i_start], upper = x[i_start + n_in - 1])
}

beta_draws_by_wave <- readRDS(file.path(artifacts_dir, "beta_draws_by_wave.rds"))

df_beta_width <- imap(beta_draws_by_wave, \(draws_wave, wave) {
  tibble(prolific_id = colnames(draws_wave)) |>
    mutate(
      time        = wave,
      beta_median = apply(draws_wave, 2, median),
      hdi         = map(prolific_id, \(id) hdi_bounds(draws_wave[, id], hdi_prob)),
      hdi_log     = map(prolific_id, \(id) hdi_bounds(log(draws_wave[, id]), hdi_prob)),
      hdi_lower   = map_dbl(hdi, "lower"),
      hdi_upper   = map_dbl(hdi, "upper"),
      width       = hdi_upper - hdi_lower,
      width_log   = map_dbl(hdi_log, \(b) b[["upper"]] - b[["lower"]])
    ) |>
    select(-hdi, -hdi_log)
}) |>
  list_rbind()

width_correlations <- df_beta_width |>
  group_by(time) |>
  summarise(rho_width     = cor(beta_median, width, method = "spearman"),
            rho_width_log = cor(beta_median, width_log, method = "spearman"),
            .groups = "drop")
print(width_correlations)

plot_width <- function(y_var, y_label, rho_var) {
  labels <- width_correlations |>
    mutate(label = sprintf("%s: Spearman rho = %.2f", time, .data[[rho_var]])) |>
    pull(label) |>
    paste(collapse = "\n")

  ggplot(df_beta_width, aes(x = beta_median, y = .data[[y_var]], colour = time)) +
    geom_point(alpha = 0.75, size = 2) +
    annotate("text", x = min(df_beta_width$beta_median), y = Inf,   # -Inf fails on a log axis
             label = paste0("[", gsub("\n", "]\n[", labels), "]"),
             hjust = 0, vjust = 1.2, size = 3.5, colour = "grey30") +
    scale_x_log10(breaks = c(1, 2, 5, 10, 20), labels = as.character(c(1, 2, 5, 10, 20))) +
    scale_colour_manual(values = c(time1 = "#4477AA", time2 = "#EE6677"),
                        labels = c(time1 = "Time 1", time2 = "Time 2")) +
    theme_minimal(base_size = 13) +
    theme(panel.grid.minor = element_blank()) +
    labs(x = "Posterior median of beta (log axis)", y = y_label, colour = NULL)
}

p_width     <- plot_width("width", sprintf("Width of the %d%% HDI of beta", round(100 * hdi_prob)), "rho_width")
p_width_log <- plot_width("width_log", sprintf("Width of the %d%% HDI of log(beta)", round(100 * hdi_prob)), "rho_width_log")

p_beta_posterior_width <- (p_width | p_width_log) +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A")

ggsave(file.path(output_dir, "beta_posterior_width.png"), plot = p_beta_posterior_width,
       width = 15, height = 6.5, dpi = 300, bg = "white")
write_csv(df_beta_width, file.path(artifacts_dir, "beta_posterior_width.csv"))
