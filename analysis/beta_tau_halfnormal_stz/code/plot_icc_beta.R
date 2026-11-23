#### ICC OF BETA: TABLE AND POSTERIOR PLOT ####
# reads:  artifacts/brms_icc_beta_plain.rds
# writes: output/test-retest across sessions/icc_beta.csv,
#         output/test-retest across sessions/icc_beta_posterior.{pdf,png}
#
# Eq. [4]: ICC = sigma_b^2 / (sigma_b^2 + sigma_e^2), computed per posterior draw.

icc_threshold <- 0.80   # Hypothesis 2: ICC > 0.80

fit_beta_icc_plain <- readRDS(file.path(artifacts_dir, "brms_icc_beta_plain.rds"))

#### 1. ICC PER POSTERIOR DRAW ####

draws_df_beta <- as_draws_df(fit_beta_icc_plain, variable = c("sd_id__Intercept", "sigma"))
sigma_b2       <- draws_df_beta$sd_id__Intercept^2
sigma_e2       <- draws_df_beta$sigma^2
icc_beta_draws <- sigma_b2 / (sigma_b2 + sigma_e2)

icc_beta_table <- tibble(
  version          = "No measurement error",
  parameter        = "beta (raw scale)",
  n_participants   = n_distinct(fit_beta_icc_plain$data$id),
  icc_median       = median(icc_beta_draws),
  icc_lower_95     = quantile(icc_beta_draws, 0.025),
  icc_upper_95     = quantile(icc_beta_draws, 0.975),
  p_icc_above_0.80 = mean(icc_beta_draws > icc_threshold),
  sigma_b_median   = median(sqrt(sigma_b2)),
  sigma_e_median   = median(sqrt(sigma_e2))
)
print(icc_beta_table)
write_csv(icc_beta_table, file.path(output_retest_dir, "icc_beta.csv"))

#### 2. POSTERIOR PLOT ####

# Bounded parameter: x axis over its full range [0, 1]
icc_median <- median(icc_beta_draws)

p_icc_beta <- ggplot(tibble(icc = icc_beta_draws), aes(x = icc, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40", linewidth = 0.7) +
  geom_vline(xintercept = icc_median, linetype = "dashed", colour = "grey65", linewidth = 0.4) +
  annotate("text", x = icc_median, y = Inf,
           label = sprintf("[median = %.2f]", icc_median),
           hjust = 1.05, vjust = 1.4, size = 3.2, colour = "grey40") +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid   = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y  = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y  = element_blank(),
    axis.line.x  = element_line(colour = "grey30")
  ) +
  labs(x = "ICC of beta, day 1 vs day 2") +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.3), clip = "off")

plot_name <- "icc_beta_posterior"

ggsave(file.path(output_retest_dir, paste0(plot_name, ".pdf")), plot = p_icc_beta,
       width = 10, height = 4, bg = "white")
ggsave(file.path(output_retest_dir, paste0(plot_name, ".png")), plot = p_icc_beta,
       width = 10, height = 4, dpi = 300, bg = "white")
