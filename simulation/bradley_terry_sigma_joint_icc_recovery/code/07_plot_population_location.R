#### FIGURE 1: POPULATION LOCATION AND SCALE ####
# reads:  artifacts/<run>/draws_pop.rds, artifacts/recovery_population.rds
# writes: output/07_population_location.{pdf,png}, artifacts/figure_1.rds
#
# A: posterior of mu_log_sigma, s_log_sigma and delta_log_sigma per run, true value as a dotted
#    blue line. mu, s: draws' range +-20% (s from 0 at most); delta (an effect): symmetric about 0.
# B: the 16 item means m_k and 16 session shifts delta_k: true vs posterior median, 95% interval.

recovery_population <- readRDS(file.path(artifacts_dir, "recovery_population.rds"))

df_location <- map(run_names, \(run) {
  readRDS(file.path(artifacts_dir, run, "draws_pop.rds")) |>
    as_tibble() |>
    select(mu_log_sigma, s_log_sigma, delta_log_sigma) |>
    pivot_longer(everything(), names_to = "parameter", values_to = "value") |>
    mutate(run = run)
}) |>
  list_rbind() |>
  left_join(select(recovery_population, run, parameter, true_value), by = c("run", "parameter"))

# Per-parameter x range (shared across runs), drawn with geom_blank
df_limits <- df_location |>
  group_by(parameter) |>
  summarise(lo = min(value), hi = max(value)) |>
  mutate(lo_plot = case_when(parameter == "delta_log_sigma" ~ -max(abs(c(lo, hi))),
                             parameter == "s_log_sigma"     ~ max(0, lo - 0.2 * (hi - lo)),
                             TRUE                           ~ lo - 0.2 * (hi - lo)),
         hi_plot = if_else(parameter == "delta_log_sigma",  max(abs(c(lo, hi))), hi + 0.2 * (hi - lo))) |>
  select(parameter, lo_plot, hi_plot) |>
  pivot_longer(-parameter, values_to = "value") |>
  expand_grid(run = run_names)

panel_a <- ggplot(df_location, aes(x = value, y = 0)) +
  stat_slab(fill = "gray80", normalize = "panels") +
  stat_pointinterval(.width = 0.90, point_size = 2) +
  geom_vline(data = distinct(df_location, run, parameter, true_value), aes(xintercept = true_value),
             linetype = "dotted", colour = "blue", linewidth = 0.8) +
  geom_vline(data = tibble(parameter = "delta_log_sigma"), aes(xintercept = 0),
             linetype = "dashed", colour = "grey40", linewidth = 0.5) +
  geom_blank(data = df_limits, aes(x = value)) +
  facet_grid(run ~ parameter, scales = "free_x",
             labeller = labeller(run = setNames(str_wrap(run_labels, 22), names(run_labels)))) +
  theme_minimal(base_size = 13) +
  theme(panel.grid = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank(),
        axis.ticks.y = element_blank(), axis.line.x = element_line(colour = "grey30"),
        strip.text.y = element_text(angle = 0, hjust = 0), panel.spacing.x = unit(1.2, "lines")) +
  labs(x = "Posterior (log sigma scale)") +
  coord_cartesian(ylim = c(0, 1.1))

# B: item means and shifts
df_items <- recovery_population |>
  filter(str_detect(parameter, "^(m|delta_u)\\[")) |>
  mutate(type = if_else(str_detect(parameter, "^m"), "Item mean m_k", "Session shift delta_k"))
item_limits <- range(c(df_items$true_value, df_items$lower, df_items$upper))

panel_b <- ggplot(df_items, aes(x = true_value, y = median, colour = type)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0, alpha = 0.5) +
  geom_point(alpha = 0.75, size = 2) +
  facet_wrap(~ run, labeller = labeller(run = setNames(sprintf("Run %d", seq_along(run_labels)), names(run_labels)))) +
  scale_colour_manual(values = c("Item mean m_k" = "#4477AA", "Session shift delta_k" = "#EE6677"), name = NULL) +
  coord_equal(xlim = item_limits, ylim = item_limits) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank(), legend.position = "top") +
  labs(x = "True value", y = "Posterior median (95% interval)")

figure_1 <- panel_a / panel_b + plot_layout(heights = c(1.3, 1)) +
  plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))

saveRDS(figure_1, file.path(artifacts_dir, "figure_1.rds"))
plot_name <- "07_population_location"
ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = figure_1, width = 10, height = 10, bg = "white")
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = figure_1, width = 10, height = 10, dpi = 300, bg = "white")
