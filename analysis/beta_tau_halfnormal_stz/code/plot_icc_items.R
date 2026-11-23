#### ICC OF ITEM PROFILES (CBCU, PHQ-9): TABLES AND POSTERIOR PLOTS ####
# reads:  artifacts/brms_icc_utility.rds, artifacts/brms_icc_phq9_items.rds
# writes: output/test-retest across sessions/icc_utility.csv, icc_phq9_items.csv,
#         output/test-retest across sessions/icc_utility_posterior.{pdf,png},
#         icc_phq9_items_posterior.{pdf,png}, icc_items_comparison_posterior.{pdf,png}
#
# ICC (agreement), eq. [2], per posterior draw, from squared SDs:
#   ICC = s2_participant:item / (s2_participant:item + s2_occasion:item + s2_residual)
# The item variance is left out of both numerator and denominator.

icc_threshold <- 0.80   # Hypothesis 2: ICC > 0.80

icc_item_measures <- tibble(
  measure   = c("CBCU utilities", "PHQ-9 items"),
  fit_file  = c("brms_icc_utility.rds", "brms_icc_phq9_items.rds"),
  file_stem = c("icc_utility", "icc_phq9_items")
)

#### 1. VARIANCE COMPONENTS AND ICC PER POSTERIOR DRAW ####

df_item_draws <- pmap(icc_item_measures, \(measure, fit_file, file_stem) {
  fit <- readRDS(file.path(artifacts_dir, fit_file))
  as_draws_df(fit, variable = c("sd_item__Intercept", "sd_participant:item__Intercept",
                                "sd_occasion:item__Intercept", "sigma")) |>
    as_tibble() |>
    transmute(measure              = measure,
              n_participants       = n_distinct(fit$data$participant),
              var_item             = sd_item__Intercept^2,
              var_participant_item = `sd_participant:item__Intercept`^2,
              var_occasion_item    = `sd_occasion:item__Intercept`^2,
              var_residual         = sigma^2,
              icc = var_participant_item / (var_participant_item + var_occasion_item + var_residual))
}) |>
  list_rbind() |>
  mutate(measure = factor(measure, levels = icc_item_measures$measure))

# One table per measure: median and 95% CrI of the ICC and each variance component
for (k in seq_len(nrow(icc_item_measures))) {
  icc_table <- df_item_draws |>
    filter(measure == icc_item_measures$measure[k]) |>
    pivot_longer(c(icc, var_participant_item, var_occasion_item, var_residual, var_item),
                 names_to = "quantity", values_to = "value") |>
    mutate(quantity = factor(quantity, levels = c("icc", "var_participant_item", "var_occasion_item",
                                                  "var_residual", "var_item"))) |>
    group_by(measure, quantity) |>
    summarise(median         = median(value),
              lower_95       = quantile(value, 0.025),
              upper_95       = quantile(value, 0.975),
              n_participants = first(n_participants),
              .groups = "drop")
  print(icc_table)
  write_csv(icc_table, file.path(output_retest_dir, paste0(icc_item_measures$file_stem[k], ".csv")))
}

#### 2. SINGLE-MEASURE POSTERIOR PLOTS ####

theme_icc <- theme_minimal(base_size = 13) +
  theme(
    panel.grid   = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y  = element_blank(),
    axis.line.x  = element_line(colour = "grey30")
  )

save_icc_plot <- function(plot, plot_name) {
  ggsave(file.path(output_retest_dir, paste0(plot_name, ".pdf")), plot = plot,
         width = 10, height = 4, bg = "white")
  ggsave(file.path(output_retest_dir, paste0(plot_name, ".png")), plot = plot,
         width = 10, height = 4, dpi = 300, bg = "white")
}

# Bounded parameter: x axis over its full range [0, 1]
for (k in seq_len(nrow(icc_item_measures))) {
  df_one     <- df_item_draws |> filter(measure == icc_item_measures$measure[k])
  icc_median <- median(df_one$icc)

  p_icc_one <- ggplot(df_one, aes(x = icc, y = 0)) +
    stat_slab(fill = "gray80") +
    stat_pointinterval(.width = 0.90, point_size = 3) +
    geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40", linewidth = 0.7) +
    geom_vline(xintercept = icc_median, linetype = "dashed", colour = "grey65", linewidth = 0.4) +
    annotate("text", x = icc_median, y = Inf, label = sprintf("[median = %.2f]", icc_median),
             hjust = 1.05, vjust = 1.4, size = 3.2, colour = "grey40") +
    theme_icc +
    labs(x = paste0("ICC of ", icc_item_measures$measure[k], ", occasion 1 vs occasion 2")) +
    coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.3), clip = "off")

  save_icc_plot(p_icc_one, paste0(icc_item_measures$file_stem[k], "_posterior"))
}

#### 3. COMPARISON PLOT: BOTH MEASURES ####

pal <- c("CBCU utilities" = "#4477AA", "PHQ-9 items" = "#EE6677")

icc_labels <- df_item_draws |>
  group_by(measure) |>
  summarise(icc_median = median(icc)) |>
  mutate(label = sprintf("%s: [median = %.2f]", measure, icc_median))

p_icc_items <- ggplot(df_item_draws, aes(x = icc, y = 0, fill = measure, colour = measure)) +
  stat_slab(alpha = 0.50) +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40", linewidth = 0.7) +
  geom_vline(data = icc_labels, aes(xintercept = icc_median, colour = measure),
             linetype = "dashed", linewidth = 0.4, show.legend = FALSE) +
  scale_fill_manual(values = pal, labels = setNames(icc_labels$label, icc_labels$measure),
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
  labs(x = "ICC of item profiles, occasion 1 vs occasion 2", fill = NULL) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.3), clip = "off")

save_icc_plot(p_icc_items, "icc_items_comparison_posterior")
