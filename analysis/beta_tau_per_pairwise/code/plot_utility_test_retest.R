#### PLOT UTILITY TEST-RETEST SCATTER ####

df_participant_parameters <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

df_utility_long <- df_participant_parameters |>
  select(prolific_id, time, u_1:u_15) |>
  pivot_longer(u_1:u_15, names_to = "item", values_to = "u")

df_utility_wide <- df_utility_long |>
  pivot_wider(names_from = time, values_from = u, names_prefix = "u_") |>
  filter(!is.na(u_time1), !is.na(u_time2))

stopifnot(length(df_utility_wide$u_time1) == length(df_utility_wide$u_time2))

shared_limits <- range(c(df_utility_wide$u_time1, df_utility_wide$u_time2), na.rm = TRUE)
axis_breaks   <- seq(shared_limits[1], shared_limits[2], length.out = 4)
pearson_r     <- cor(df_utility_wide$u_time1, df_utility_wide$u_time2, method = "pearson")

p_utility_retest <- ggplot(df_utility_wide, aes(x = u_time1, y = u_time2)) +
  geom_point(colour = "#4477AA", alpha = 0.75, size = 2) +
  geom_smooth(method = "lm", se = FALSE, colour = "#EE6677", linewidth = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60") +
  annotate(
    "text",
    x = Inf, y = Inf,
    label = sprintf("[Pearson r = %.2f]", pearson_r),
    hjust = 1.05, vjust = 1.4,
    size = 3.5, colour = "grey30"
  ) +
  scale_x_continuous(breaks = axis_breaks) +
  scale_y_continuous(breaks = axis_breaks) +
  coord_equal(xlim = shared_limits, ylim = shared_limits, clip = "off") +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank()) +
  labs(x = "Time 1 utility (u)", y = "Time 2 utility (u)")

plot_name <- "utility_test_retest_scatter"

ggsave(
  file.path(output_dir, paste0(plot_name, ".png")),
  plot = p_utility_retest,
  width = 10, height = 8, dpi = 300, bg = "white"
)
