#### PLOT GROUP-MEAN UTILITY VS. MAPPED PHQ9-ITEM SCATTER (15 POINTS) ####
# Different-scale comparison, same convention as plot_utility_vs_phq9_item.R: no coord_equal(),
# no y=x diagonal. Points coloured by phq9_item (9 groups, reusing that script's Tol muted palette)
# since multiple u-items share a phq9-item group.

tol_muted <- c("#332288", "#117733", "#44AA99", "#88CCEE", "#DDCC77",
               "#CC6677", "#AA4499", "#882255", "#999933")

pearson_r <- cor(df_mean_utility_vs_phq9_item$u_group_mean, df_mean_utility_vs_phq9_item$phq9_group_mean, method = "pearson")

p_mean_utility_vs_phq9_item <- ggplot(df_mean_utility_vs_phq9_item, aes(x = u_group_mean, y = phq9_group_mean)) +
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
  labs(x = "Mean utility (u), across subjects", y = "Mean PHQ9 item score, across subjects")

plot_name <- "mean_utility_vs_mean_phq9_item"

ggsave(
  file.path(output_dir, paste0(plot_name, ".pdf")),
  plot = p_mean_utility_vs_phq9_item,
  width = 10, height = 8, bg = "white"
)

ggsave(
  file.path(output_dir, paste0(plot_name, ".png")),
  plot = p_mean_utility_vs_phq9_item,
  width = 10, height = 8, dpi = 300, bg = "white"
)
