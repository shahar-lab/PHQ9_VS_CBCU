#### PLOT POPULATION POSTERIORS ####
# reads: artifacts/draws_pop.rds, true_population.rds, population_table.rds, true_parameters.rds
# writes: output/07_location_posteriors.pdf/png, 07_scale_posteriors.pdf/png,
#         artifacts/p_location_posteriors.rds, p_scale_posteriors.rds
#
# Three reference lines per panel:
#   Population value (blue, dashed): the value set in main.R that the subjects were drawn from
#   Sampled value    (red, solid):   the same statistic in the subjects actually drawn
#   Posterior median (grey, dashed)

draws_pop        <- readRDS(file.path(artifacts_dir, "draws_pop.rds"))
true_population  <- readRDS(file.path(artifacts_dir, "true_population.rds"))
population_table <- readRDS(file.path(artifacts_dir, "population_table.rds"))
true_parameters  <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))

# Sample statistic on the scale of each hyperparameter: beta_location and beta_scale
# are the mean and SD of log(beta)
sample_stat_df <- tibble(
  parameter   = c("beta_location", "beta_scale", "tau_location", "tau_scale"),
  sample_stat = c(mean(log(true_parameters$beta)), sd(log(true_parameters$beta)),
                  mean(true_parameters$tau),       sd(true_parameters$tau))
)

draws_long <- draws_pop |>
  select(all_of(true_population$stan_name)) |>
  pivot_longer(everything(), names_to = "stan_name", values_to = "value") |>
  left_join(true_population, by = "stan_name") |>
  mutate(parameter = factor(parameter, levels = true_population$parameter))

stats_df <- population_table |>
  left_join(sample_stat_df, by = "parameter") |>
  mutate(parameter = factor(parameter, levels = true_population$parameter))

# 20% padding around each panel's posterior range, always including the population
# value and the sampled value
anchor_df <- draws_long |>
  left_join(sample_stat_df, by = "parameter") |>
  group_by(parameter) |>
  reframe(value = {
    r <- range(c(value, true_value[1], sample_stat[1]))
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
               aes(xintercept = true_value, colour = "Population value", linetype = "Population value"),
               linewidth = 0.7) +
    geom_vline(data = filter(stats_df, parameter %in% keep_parameters),
               aes(xintercept = sample_stat, colour = "Sampled value", linetype = "Sampled value"),
               linewidth = 0.7) +
    geom_vline(data = filter(stats_df, parameter %in% keep_parameters),
               aes(xintercept = median, colour = "Posterior median", linetype = "Posterior median"),
               linewidth = 0.4) +
    geom_text(data = filter(stats_df, parameter %in% keep_parameters),
              aes(x = median, y = Inf, label = sprintf("[median = %.2f]", median)),
              inherit.aes = FALSE, hjust = -0.05, vjust = 1.4, size = 3, colour = "grey40") +
    geom_blank(data = filter(anchor_df, parameter %in% keep_parameters), aes(x = value, y = 0)) +
    facet_wrap(~parameter, scales = "free_x") +
    scale_colour_manual(values = c("Population value" = "#4477AA", "Sampled value" = "#EE6677",
                                   "Posterior median" = "grey65")) +
    scale_linetype_manual(values = c("Population value" = "dashed", "Sampled value" = "solid",
                                     "Posterior median" = "dashed")) +
    theme_minimal(base_size = 13) +
    theme(panel.grid = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank(),
          axis.ticks.y = element_blank(), axis.line.x = element_line(colour = "grey30"),
          legend.position = "bottom") +
    labs(x = "Posterior value", colour = NULL, linetype = NULL) +
    coord_cartesian(clip = "off")

  file_stem <- file.path(output_dir, paste0("07_", suffix, "_posteriors"))
  ggsave(paste0(file_stem, ".pdf"), plot = p, width = 10, height = 4, bg = "white")
  ggsave(paste0(file_stem, ".png"), plot = p, width = 10, height = 4, dpi = 300, bg = "white")
  saveRDS(p, file.path(artifacts_dir, paste0("p_", suffix, "_posteriors.rds")))
}
