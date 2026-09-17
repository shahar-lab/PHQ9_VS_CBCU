#### PLOT UTILITY VS. MAPPED PHQ9-ITEM SCATTER (POOLED ACROSS ALL 9 GROUPS) ####
# Different-scale comparison (utility vs. PHQ9 item score): neither coord_equal() nor the y=x
# diagonal reference line is used, matching this folder's convention in plot_phq9_parameter_scatter.R.
# Points are coloured by phq9_item so the 9 mapped groups remain visually distinguishable within
# the single pooled scatter.

# ASSUMED[palette choice for 9 categories]: Paul Tol muted palette (10-colour capacity) used per
# COLOR_STANDARD.md, since Okabe-Ito tops out at 8 and this plot has 9 phq9_item groups.
tol_muted <- c("#332288", "#117733", "#44AA99", "#88CCEE", "#DDCC77",
               "#CC6677", "#AA4499", "#882255", "#999933")

pearson_r <- cor(df_utility_phq9_item_long$u_value, df_utility_phq9_item_long$phq9_value, method = "pearson")

p_utility_vs_phq9_item <- ggplot(df_utility_phq9_item_long, aes(x = u_value, y = phq9_value)) +
  geom_point(aes(colour = phq9_item), alpha = 0.75, size = 2) +
  geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
  annotate(
    "text",
    x = Inf, y = Inf,
    label = sprintf("[Pearson r = %.2f]", pearson_r),
    hjust = 1.05, vjust = 1.4,
    size = 3.5, colour = "grey30"
  ) +
  scale_colour_manual(values = tol_muted, name = "PHQ9 item") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "Utility (u), session-averaged", y = "PHQ9 item score, session-averaged")

plot_name <- "utility_vs_phq9_item"

ggsave(
  file.path(output_dir, paste0(plot_name, ".pdf")),
  plot = p_utility_vs_phq9_item,
  width = 10, height = 8, bg = "white"
)

ggsave(
  file.path(output_dir, paste0(plot_name, ".png")),
  plot = p_utility_vs_phq9_item,
  width = 10, height = 8, dpi = 300, bg = "white"
)
