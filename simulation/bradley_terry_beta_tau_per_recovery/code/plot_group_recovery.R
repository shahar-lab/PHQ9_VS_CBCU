#### PLOT GROUP-LEVEL RECOVERY ####

plot_df <- data.frame(
  variable      = group_recovery$variable,
  true_val      = group_recovery$true_value,
  recovered_val = group_recovery$recovered_value
)
plot_df <- plot_df[complete.cases(plot_df), ]
stopifnot(nrow(plot_df) == nrow(group_recovery))

# ASSUMED[per-variable scale mismatch]: mu_*/sigma_* hyperparameters live on different
# natural scales (e.g. exponential(2) sigmas near zero vs normal(0,2) mus), so shared axis
# limits, a pooled lm trend, and a pooled Pearson r are computed per variable (facet) rather
# than pooled across all 8, while still combining them into one shared plot object coloured
# by variable name per the spec.
okabe_ito <- c(
  "#E69F00", "#56B4E9", "#009E73", "#F0E442",
  "#0072B2", "#D55E00", "#CC79A7", "#000000"
)

per_var_stats <- plot_df |>
  group_by(variable) |>
  summarise(
    r_label = sprintf("[Pearson r = %.2f]", cor(true_val, recovered_val, method = "pearson")),
    x       = Inf,
    y       = Inf,
    .groups = "drop"
  )

# per-facet shared square range, anchored to the TRUE value's own scale rather than the
# true/recovered gap: with only one point per facet, padding around just c(true_val,
# recovered_val) auto-zooms every facet to its own error, making a 6% miss and a 70% miss
# look equally "off-diagonal" (both end up near the plot edges). Anchoring the range to
# span 0 through true_val (plus a margin) instead means distance from the diagonal reflects
# the actual recovery error relative to the true value, comparably across all 8 hyperparameters.
# Achieved with facet_wrap(scales = "free") plus invisible geom_blank() anchor points, which
# forces the free per-facet scales to span an identical range on x and y without a new dependency.
range_pad <- function(true_val) {
  margin <- max(abs(true_val), 0.1) * 0.5
  c(min(0, true_val) - margin, max(0, true_val) + margin)
}

anchor_df <- plot_df |>
  group_by(variable) |>
  reframe(range_val = range_pad(true_val[1])) |>
  transmute(variable, true_val = range_val, recovered_val = range_val)

# four explicit tick marks per facet, computed from that facet's own shared square range
four_breaks <- function(x) {
  lims <- range(x, na.rm = TRUE)
  seq(lims[1], lims[2], length.out = 4)
}

p_group <- ggplot(plot_df, aes(x = true_val, y = recovered_val, colour = variable)) +
  geom_point(alpha = 0.85, size = 2.5) +
  geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
  geom_blank(data = anchor_df, aes(x = true_val, y = recovered_val)) +
  geom_text(data = per_var_stats, aes(x = x, y = y, label = r_label),
            inherit.aes = FALSE, hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
  facet_wrap(~variable, scales = "free") +
  scale_colour_manual(values = okabe_ito) +
  scale_x_continuous(breaks = four_breaks) +
  scale_y_continuous(breaks = four_breaks) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank(), legend.position = "none") +
  labs(x = "True value", y = "Recovered value", colour = "Hyperparameter")

ggsave(file.path(output_dir, "group_recovery.pdf"), plot = p_group, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "group_recovery.png"), plot = p_group, width = 10, height = 8, dpi = 300, bg = "white")
