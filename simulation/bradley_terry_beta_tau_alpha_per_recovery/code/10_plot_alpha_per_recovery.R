#### PLOT ALPHA_PER RECOVERY ####
# reads: artifacts/recovered_parameters.rds · writes: output/10_alpha_per_recovery.{pdf,png}, artifacts/p_alpha_per.rds

plot_df <- readRDS(file.path(artifacts_dir, "recovered_parameters.rds")) |>
  filter(parameter == "alpha_per") |>
  transmute(true_val = true_value, recovered_val = recovered_value) |>
  filter(complete.cases(true_val, recovered_val))

shared_limits <- range(c(plot_df$true_val, plot_df$recovered_val))
axis_breaks   <- round(seq(shared_limits[1], shared_limits[2], length.out = 4), 2)
pearson_r     <- cor(plot_df$true_val, plot_df$recovered_val, method = "pearson")

p_alpha_per <- ggplot(plot_df, aes(x = true_val, y = recovered_val)) +
  geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
  annotate("text", x = Inf, y = Inf, label = sprintf("[Pearson r = %.2f]", pearson_r),
           hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
  scale_x_continuous(breaks = axis_breaks) +
  scale_y_continuous(breaks = axis_breaks) +
  coord_equal(xlim = shared_limits, ylim = shared_limits, clip = "off") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "True alpha_per", y = "Recovered alpha_per")

ggsave(file.path(output_dir, "10_alpha_per_recovery.pdf"), plot = p_alpha_per, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "10_alpha_per_recovery.png"), plot = p_alpha_per, width = 10, height = 8, dpi = 300, bg = "white")
saveRDS(p_alpha_per, file.path(artifacts_dir, "p_alpha_per.rds"))
