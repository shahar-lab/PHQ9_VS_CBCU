#### ICC OF SIGMA: TABLE AND POSTERIOR PLOTS ####
# reads:  artifacts/brms_icc_sigma_{me,plain,day_me,day_plain}.rds
# writes: output/test-retest across sessions/icc/icc_sigma.csv (one row per version),
#         output/test-retest across sessions/icc/icc_sigma_posterior.{pdf,png} (both versions, no day effect),
#         output/test-retest across sessions/icc/icc_sigma_without_ms_posterior.{pdf,png},
#         output/test-retest across sessions/icc/icc_sigma_day_effect_posterior.{pdf,png}
#           (agreement vs consistency, one panel per measurement-error version)
#
# ICC = sigma_b^2 / (sigma_b^2 + sigma_e^2), computed per posterior draw.
# No day effect: the day 2 shift is part of sigma_e^2 -> absolute agreement.
# Day effect:    the day 2 shift (delta) is a fixed effect  -> consistency.
# Plots 1-2 match analysis/beta_tau_halfnormal_stz/code/plot_icc_beta.R.

icc_threshold <- 0.80   # Hypothesis 2: ICC > 0.80

icc_sigma_fits <- tribble(
  ~version,                 ~icc_type,     ~fit_file,
  "Measurement error (se)", "Agreement",   "brms_icc_sigma_me.rds",
  "No measurement error",   "Agreement",   "brms_icc_sigma_plain.rds",
  "Measurement error (se)", "Consistency", "brms_icc_sigma_day_me.rds",
  "No measurement error",   "Consistency", "brms_icc_sigma_day_plain.rds"
)

#### 1. ICC PER POSTERIOR DRAW ####

df_icc_sigma_draws <- pmap(icc_sigma_fits, \(version, icc_type, fit_file) {
  fit <- readRDS(file.path(artifacts_dir, fit_file))
  df  <- as_draws_df(fit) |> as_tibble()
  tibble(version   = version,
         icc_type  = icc_type,
         sigma_b   = df$sd_id__Intercept,   # how much participants differ from each other
         sigma_e   = df$sigma,              # how much one participant's sigma moves between days
         day_shift = if ("b_daytime2" %in% names(df)) df$b_daytime2 else NA_real_,   # day 2 - day 1
         icc       = sigma_b^2 / (sigma_b^2 + sigma_e^2),
         n_ids     = n_distinct(fit$data$id))
}) |>
  list_rbind() |>
  mutate(version  = factor(version, levels = c("Measurement error (se)", "No measurement error")),
         icc_type = factor(icc_type, levels = c("Agreement", "Consistency")))

icc_sigma_table <- df_icc_sigma_draws |>
  group_by(icc_type, version) |>
  summarise(parameter          = "sigma (raw scale)",
            day_effect         = all(!is.na(day_shift)),
            n_participants     = first(n_ids),
            icc_median         = median(icc),
            icc_lower_95       = quantile(icc, 0.025),
            icc_upper_95       = quantile(icc, 0.975),
            p_icc_above_0.80   = mean(icc > icc_threshold),
            sigma_b_median     = median(sigma_b),
            sigma_e_median     = median(sigma_e),
            day_shift_median   = median(day_shift),
            day_shift_lower_95 = quantile(day_shift, 0.025, na.rm = TRUE),
            day_shift_upper_95 = quantile(day_shift, 0.975, na.rm = TRUE),
            .groups = "drop") |>
  relocate(version, icc_type, parameter, day_effect)
print(icc_sigma_table, width = Inf)
write_csv(icc_sigma_table, file.path(output_retest_icc_dir, "icc_sigma.csv"))

#### 2. POSTERIOR PLOT: BOTH VERSIONS, NO DAY EFFECT (AS FOR BETA) ####

# Bounded parameter: x axis over its full range [0, 1]. Medians given in the legend entries.
pal <- c("Measurement error (se)" = "#4477AA", "No measurement error" = "#EE6677")

theme_icc <- theme_minimal(base_size = 13) +
  theme(
    panel.grid   = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y  = element_blank(),
    axis.line.x  = element_line(colour = "grey30")
  )

save_icc_plot <- function(p, plot_name, height = 4) {
  ggsave(file.path(output_retest_icc_dir, paste0(plot_name, ".pdf")), plot = p,
         width = 10, height = height, bg = "white")
  ggsave(file.path(output_retest_icc_dir, paste0(plot_name, ".png")), plot = p,
         width = 10, height = height, dpi = 300, bg = "white")
}

df_icc_agreement <- df_icc_sigma_draws |> filter(icc_type == "Agreement")
icc_sigma_labels <- icc_sigma_table |>
  filter(icc_type == "Agreement") |>
  mutate(label = sprintf("%s: [median = %.2f]", version, icc_median))

# normalize = "groups": each slab scaled to its own maximum
p_icc_sigma <- ggplot(df_icc_agreement, aes(x = icc, y = 0, fill = version, colour = version)) +
  stat_slab(alpha = 0.50, normalize = "groups") +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40", linewidth = 0.7) +
  geom_vline(data = icc_sigma_labels, aes(xintercept = icc_median, colour = version),
             linetype = "dashed", linewidth = 0.4, show.legend = FALSE) +
  scale_fill_manual(values = pal, labels = setNames(icc_sigma_labels$label, icc_sigma_labels$version),
                    guide = guide_legend(override.aes = list(alpha = 0.7))) +
  scale_colour_manual(values = pal, guide = "none") +
  theme_icc +
  theme(
    legend.position        = "inside",
    legend.position.inside = c(0.02, 0.95),
    legend.justification   = c("left", "top"),
    legend.background      = element_blank(),
    legend.key             = element_blank()
  ) +
  labs(x = "ICC of sigma, day 1 vs day 2", fill = NULL) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.3), clip = "off")

save_icc_plot(p_icc_sigma, "icc_sigma_posterior")

#### 3. POSTERIOR PLOT: NO MEASUREMENT ERROR ONLY, NO DAY EFFECT (AS FOR BETA) ####

df_icc_sigma_without_ms <- df_icc_agreement |> filter(version == "No measurement error")
icc_sigma_median_without_ms <- median(df_icc_sigma_without_ms$icc)

p_icc_sigma_without_ms <- ggplot(df_icc_sigma_without_ms, aes(x = icc, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40", linewidth = 0.7) +
  geom_vline(xintercept = icc_sigma_median_without_ms, linetype = "dashed", colour = "grey65", linewidth = 0.4) +
  annotate("text", x = icc_sigma_median_without_ms, y = Inf,
           label = sprintf("[median = %.2f]", icc_sigma_median_without_ms),
           hjust = 1.05, vjust = 1.4, size = 3.2, colour = "grey40") +
  theme_icc +
  labs(x = "ICC of sigma, day 1 vs day 2") +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.3), clip = "off")

save_icc_plot(p_icc_sigma_without_ms, "icc_sigma_without_ms_posterior")

#### 4. POSTERIOR PLOT: AGREEMENT VS CONSISTENCY, PER MEASUREMENT-ERROR VERSION ####

pal_type <- c("Agreement" = "#EE6677", "Consistency" = "#228833")

icc_type_labels <- icc_sigma_table |>
  mutate(label = if_else(day_effect,
                         sprintf("Consistency (day effect, shift = %.2f): [median = %.2f]",
                                 day_shift_median, icc_median),
                         sprintf("Agreement (no day effect): [median = %.2f]", icc_median)),
         y_label = if_else(icc_type == "Agreement", 1.25, 1.10))

p_icc_sigma_day <- ggplot(df_icc_sigma_draws, aes(x = icc, y = 0, fill = icc_type, colour = icc_type)) +
  stat_slab(alpha = 0.50, normalize = "groups") +   # each slab to its own maximum (ME agreement piles up at 1)
  stat_pointinterval(.width = 0.90, point_size = 3, position = position_dodge(width = 0.12)) +
  geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40", linewidth = 0.7) +
  geom_vline(data = icc_type_labels, aes(xintercept = icc_median, colour = icc_type),
             linetype = "dashed", linewidth = 0.4, show.legend = FALSE) +
  geom_text(data = icc_type_labels, aes(x = 0.01, y = y_label, label = label, colour = icc_type),
            hjust = 0, size = 3.4, inherit.aes = FALSE, show.legend = FALSE) +
  facet_wrap(~ version, ncol = 1) +
  scale_fill_manual(values = pal_type, guide = "none") +
  scale_colour_manual(values = pal_type, guide = "none") +
  theme_icc +
  theme(strip.text = element_text(hjust = 0, face = "bold")) +
  labs(x = "ICC of sigma, day 1 vs day 2") +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.35), clip = "off")

save_icc_plot(p_icc_sigma_day, "icc_sigma_day_effect_posterior", height = 7)
