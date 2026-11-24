#### ICC DIFFERENCE: CBCU UTILITIES - PHQ-9 ITEMS ####
# reads:  artifacts/brms_icc_utility.rds, artifacts/brms_icc_phq9_items.rds
# writes: output/test-retest across sessions/icc/icc_items_difference.csv,
#         output/test-retest across sessions/icc/icc_items_difference_posterior.{pdf,png}
#
# ICC (eq. [2]) per posterior draw in each model, then difference = ICC_CBCU - ICC_PHQ9, draw by draw.
# The two models were fit separately, so draw k of one is paired with draw k of the other
# (both have 4 x 2000 = 8000 draws). This treats the two posteriors as independent: any
# correlation between the two ICCs (same 185 participants) is not modelled.

icc_from_fit <- function(fit_file) {
  as_draws_df(readRDS(file.path(artifacts_dir, fit_file)),
              variable = c("sd_participant:item__Intercept", "sd_occasion:item__Intercept", "sigma")) |>
    as_tibble() |>
    transmute(icc = `sd_participant:item__Intercept`^2 /
                (`sd_participant:item__Intercept`^2 + `sd_occasion:item__Intercept`^2 + sigma^2)) |>
    pull(icc)
}

icc_cbcu <- icc_from_fit("brms_icc_utility.rds")
icc_phq9 <- icc_from_fit("brms_icc_phq9_items.rds")
stopifnot(length(icc_cbcu) == length(icc_phq9))

icc_difference <- icc_cbcu - icc_phq9

#### 1. TABLE ####

med_diff <- median(icc_difference)
pd_diff  <- max(mean(icc_difference > 0), mean(icc_difference < 0)) * 100   # probability of direction

icc_difference_table <- tibble(
  quantity      = "ICC CBCU utilities - ICC PHQ-9 items",
  median        = med_diff,
  lower_95      = quantile(icc_difference, 0.025),
  upper_95      = quantile(icc_difference, 0.975),
  p_above_0     = mean(icc_difference > 0),
  pd_percent    = pd_diff,
  n_draws       = length(icc_difference)
)
print(icc_difference_table)
write_csv(icc_difference_table, file.path(output_retest_icc_dir, "icc_items_difference.csv"))

#### 2. POSTERIOR PLOT ####

# Effect posterior on a bounded quantity: a difference of two ICCs lies in [-1, 1],
# its full range, which is also symmetric about 0.
p_icc_difference <- ggplot(tibble(diff = icc_difference), aes(x = diff, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40", linewidth = 0.7) +
  geom_vline(xintercept = med_diff, linetype = "dashed", colour = "grey65", linewidth = 0.4) +
  annotate("text", x = med_diff, y = Inf,
           label = sprintf("[median = %.2f, pd = %.2f%%]", med_diff, pd_diff),
           hjust = -0.05, vjust = 1.4, size = 3.2, colour = "grey40") +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid   = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y  = element_blank(),
    axis.line.x  = element_line(colour = "grey30")
  ) +
  labs(x = "ICC difference (CBCU utilities - PHQ-9 items)") +
  coord_cartesian(xlim = c(-1, 1), ylim = c(0, 1.3), clip = "off")

plot_name <- "icc_items_difference_posterior"

ggsave(file.path(output_retest_icc_dir, paste0(plot_name, ".pdf")), plot = p_icc_difference,
       width = 10, height = 4, bg = "white")
ggsave(file.path(output_retest_icc_dir, paste0(plot_name, ".png")), plot = p_icc_difference,
       width = 10, height = 4, dpi = 300, bg = "white")
