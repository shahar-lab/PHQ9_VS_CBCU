#### PLOT TAU VS. PERCENT "NONE" (GENERATIVE DATA) ####

df_pct_none <- df |>
  group_by(subject) |>
  summarise(pct_none = 100 * mean(choice == "None"), .groups = "drop") |>
  mutate(tau = true_tau[subject])

pearson_r <- cor(df_pct_none$tau, df_pct_none$pct_none, method = "pearson")

p_tau_vs_pct_none <- ggplot(df_pct_none, aes(x = tau, y = pct_none)) +
  geom_point(colour = "#4477AA", alpha = 0.75, size = 2.5) +
  geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
  annotate("text", x = Inf, y = Inf,
           label = sprintf("[Pearson r = %.2f]", pearson_r),
           hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "True tau", y = "Percent \"None\" choices (generative data)")

plot_name <- "tau_vs_pct_none"

ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = p_tau_vs_pct_none, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = p_tau_vs_pct_none, width = 10, height = 8, dpi = 300, bg = "white")
