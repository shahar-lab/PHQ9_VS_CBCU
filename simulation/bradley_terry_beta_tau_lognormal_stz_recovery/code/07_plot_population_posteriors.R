#### PLOT POPULATION POSTERIORS ####
# reads: artifacts/draws_pop.rds, true_population.rds, population_table.rds
# writes: output/07_location_posteriors.pdf/png, 07_scale_posteriors.pdf/png,
#         artifacts/p_location_posteriors.rds, p_scale_posteriors.rds

draws_pop        <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))
true_population  <- readRDS(file.path(artifacts_dir, "true_population.rds"))
population_table <- readRDS(file.path(artifacts_dir, "population_table.rds"))

draws_long <- draws_pop |>
  select(all_of(true_population$stan_name)) |>
  pivot_longer(everything(), names_to = "stan_name", values_to = "value") |>
  left_join(true_population, by = "stan_name") |>
  mutate(parameter = factor(parameter, levels = true_population$parameter))

stats_df <- population_table |>
  mutate(parameter = factor(parameter, levels = true_population$parameter))

# 20% padding around each panel's posterior range, always including the true value
anchor_df <- draws_long |>
  group_by(parameter) |>
  reframe(value = {
    r <- range(c(value, true_value[1]))
    c(r[1] - 0.20 * diff(r), r[2] + 0.20 * diff(r))
  })

# beta_location and beta_scale are on the log(beta) scale
for (suffix in c("location", "scale")) {
  keep_parameters <- true_population$parameter[str_ends(true_population$parameter, suffix)]

  p <- ggplot(filter(draws_long, parameter %in% keep_parameters), aes(x = value, y = 0)) +
    stat_slab(fill = "gray80") +
    stat_pointinterval(aes(linewidth = after_stat(-.width)), .width = c(0.80, 0.90), point_size = 3) +
    scale_linewidth_continuous(range = c(1, 2), guide = "none") +
    geom_vline(data = filter(stats_df, parameter %in% keep_parameters),
               aes(xintercept = true_value, colour = "True value"), linetype = "dashed", linewidth = 0.7) +
    geom_vline(data = filter(stats_df, parameter %in% keep_parameters),
               aes(xintercept = median, colour = "Posterior median"), linetype = "dashed", linewidth = 0.4) +
    geom_text(data = filter(stats_df, parameter %in% keep_parameters),
              aes(x = median, y = Inf, label = sprintf("[median = %.2f]", median)),
              inherit.aes = FALSE, hjust = -0.05, vjust = 1.4, size = 3, colour = "grey40") +
    geom_blank(data = filter(anchor_df, parameter %in% keep_parameters), aes(x = value, y = 0)) +
    facet_wrap(~parameter, scales = "free_x") +
    scale_colour_manual(values = c("True value" = "#EE6677", "Posterior median" = "grey65")) +
    theme_minimal(base_size = 13) +
    theme(panel.grid = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank(),
          axis.ticks.y = element_blank(), axis.line.x = element_line(colour = "grey30"),
          legend.position = "bottom") +
    labs(x = "Posterior value", colour = NULL) +
    coord_cartesian(clip = "off")

  file_stem <- file.path(output_dir, paste0("07_", suffix, "_posteriors"))
  ggsave(paste0(file_stem, ".pdf"), plot = p, width = 10, height = 4, bg = "white")
  ggsave(paste0(file_stem, ".png"), plot = p, width = 10, height = 4, dpi = 300, bg = "white")
  saveRDS(p, file.path(artifacts_dir, paste0("p_", suffix, "_posteriors.rds")))
}
