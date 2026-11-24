#### ICC OF TAU: TABLE AND POSTERIOR PLOT (BOTH VERSIONS) ####
# reads:  artifacts/brms_icc_tau_me.rds, artifacts/brms_icc_tau_plain.rds
# writes: output/test-retest across sessions/icc/icc_tau.csv (one row per version),
#         output/test-retest across sessions/icc/icc_tau_posterior.{pdf,png} (both versions),
#         output/test-retest across sessions/icc/icc_tau_without_ms_posterior.{pdf,png}
#
# Eq. [4]: ICC = sigma_b^2 / (sigma_b^2 + sigma_e^2), computed per posterior draw.

icc_threshold <- 0.80   # Hypothesis 2: ICC > 0.80

icc_tau_fits <- c(
  "Measurement error (se)"   = "brms_icc_tau_me.rds",
  "No measurement error"     = "brms_icc_tau_plain.rds"
)

#### 1. ICC PER POSTERIOR DRAW ####

df_icc_draws <- imap(icc_tau_fits, \(fit_file, version) {
  fit <- readRDS(file.path(artifacts_dir, fit_file))
  as_draws_df(fit, variable = c("sd_id__Intercept", "sigma")) |>
    as_tibble() |>
    transmute(version = version,
              sigma_b = sd_id__Intercept, # how much participants differ from each other
              sigma_e = sigma, #how much one participant's τ moves between Day 1 and Day 2
              icc     = sigma_b^2 / (sigma_b^2 + sigma_e^2),
              n_ids   = n_distinct(fit$data$id))
}) |>
  list_rbind() |>
  mutate(version = factor(version, levels = names(icc_tau_fits)))

icc_tau_table <- df_icc_draws |>
  group_by(version) |>
  summarise(parameter        = "tau",
            n_participants   = first(n_ids),
            icc_median       = median(icc),
            icc_lower_95     = quantile(icc, 0.025),
            icc_upper_95     = quantile(icc, 0.975),
            p_icc_above_0.80 = mean(icc > icc_threshold),
            sigma_b_median   = median(sigma_b),
            sigma_e_median   = median(sigma_e))
print(icc_tau_table)
write_csv(icc_tau_table, file.path(output_retest_icc_dir, "icc_tau.csv"))

#### 2. POSTERIOR PLOT ####

# Bounded parameter: x axis over its full range [0, 1].
# The medians sit close together near 1, so each one is given in its legend entry.
pal <- c("Measurement error (se)" = "#4477AA", "No measurement error" = "#EE6677")

icc_labels <- icc_tau_table |>
  mutate(label = sprintf("%s: [median = %.2f]", version, icc_median))

p_icc_tau <- ggplot(df_icc_draws, aes(x = icc, y = 0, fill = version, colour = version)) +
  stat_slab(alpha = 0.50) +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40", linewidth = 0.7) +
  geom_vline(data = icc_labels, aes(xintercept = icc_median, colour = version),
             linetype = "dashed", linewidth = 0.4, show.legend = FALSE) +
  scale_fill_manual(values = pal, labels = setNames(icc_labels$label, icc_labels$version),
                    guide = guide_legend(override.aes = list(alpha = 0.7))) +
  scale_colour_manual(values = pal, guide = "none") +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid             = element_blank(),
    axis.title.y           = element_blank(),
    axis.text.y            = element_blank(),
    axis.ticks.y           = element_blank(),
    axis.line.y            = element_blank(),
    axis.line.x            = element_line(colour = "grey30"),
    legend.position        = "inside",
    legend.position.inside = c(0.02, 0.95),
    legend.justification   = c("left", "top"),
    legend.background      = element_blank(),
    legend.key             = element_blank()
  ) +
  labs(x = "ICC of tau, day 1 vs day 2", fill = NULL) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.3), clip = "off")

plot_name <- "icc_tau_posterior"

ggsave(file.path(output_retest_icc_dir, paste0(plot_name, ".pdf")), plot = p_icc_tau,
       width = 10, height = 4, bg = "white")
ggsave(file.path(output_retest_icc_dir, paste0(plot_name, ".png")), plot = p_icc_tau,
       width = 10, height = 4, dpi = 300, bg = "white")

#### 3. POSTERIOR PLOT: NO MEASUREMENT ERROR ONLY ####

df_icc_without_ms <- df_icc_draws |> filter(version == "No measurement error")
icc_median_without_ms <- median(df_icc_without_ms$icc)

p_icc_tau_without_ms <- ggplot(df_icc_without_ms, aes(x = icc, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(.width = 0.90, point_size = 3) +
  geom_vline(xintercept = icc_threshold, linetype = "dashed", colour = "grey40", linewidth = 0.7) +
  geom_vline(xintercept = icc_median_without_ms, linetype = "dashed", colour = "grey65", linewidth = 0.4) +
  annotate("text", x = icc_median_without_ms, y = Inf,
           label = sprintf("[median = %.2f]", icc_median_without_ms),
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
  labs(x = "ICC of tau, day 1 vs day 2") +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.3), clip = "off")

plot_name <- "icc_tau_without_ms_posterior"

ggsave(file.path(output_retest_icc_dir, paste0(plot_name, ".pdf")), plot = p_icc_tau_without_ms,
       width = 10, height = 4, bg = "white")
ggsave(file.path(output_retest_icc_dir, paste0(plot_name, ".png")), plot = p_icc_tau_without_ms,
       width = 10, height = 4, dpi = 300, bg = "white")
