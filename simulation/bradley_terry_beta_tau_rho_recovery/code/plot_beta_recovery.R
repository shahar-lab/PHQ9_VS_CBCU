#### PLOT BETA RECOVERY ####

plot_df <- data.frame(
  true_val      = beta_recovery$true_value,
  recovered_val = beta_recovery$recovered_value
)
plot_df <- plot_df[complete.cases(plot_df), ]
stopifnot(nrow(plot_df) == nrow(beta_recovery))

shared_limits <- range(c(plot_df$true_val, plot_df$recovered_val), na.rm = TRUE)
axis_breaks   <- seq(shared_limits[1], shared_limits[2], length.out = 4)
pearson_r     <- cor(plot_df$true_val, plot_df$recovered_val, method = "pearson")

p_beta <- ggplot(plot_df, aes(x = true_val, y = recovered_val)) +
  geom_point(colour = "#4477AA", alpha = 0.75, size = 2.5) +
  geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
  annotate("text", x = Inf, y = Inf,
           label = sprintf("[Pearson r = %.2f]", pearson_r),
           hjust = 1.05, vjust = 1.4, size = 3.5, colour = "grey30") +
  scale_x_continuous(breaks = axis_breaks) +
  scale_y_continuous(breaks = axis_breaks) +
  coord_equal(xlim = shared_limits, ylim = shared_limits, clip = "off") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "True beta", y = "Recovered beta")

ggsave(file.path(output_dir, "beta_recovery.pdf"), plot = p_beta, width = 10, height = 8, bg = "white")
ggsave(file.path(output_dir, "beta_recovery.png"), plot = p_beta, width = 10, height = 8, dpi = 300, bg = "white")
