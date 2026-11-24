#### PLOT HYPERPARAMETER RECOVERY ####
# reads: artifacts/draws_<session>.rds, true_population.rds, true_parameters.rds
# writes: artifacts/hyperparameter_recovery.csv / .rds,
#         output/hyperparameter_recovery.png / .pdf
#
# Posterior distribution of each population parameter, per session (rows), with
# three reference lines per panel (as in the halfnormal recovery):
#   Population value (blue, dashed): the value set in main.R that the subjects were drawn from
#   Sampled value    (red, solid):   the same statistic in the 200 subjects actually drawn
#                                     (mean and SD of the true sigma)
#   Posterior median (grey, dashed)
# sigma_location and sigma_scale are the mean and SD of sigma before truncation at 0.
# The truncation removes only P(sigma < 0) = pnorm(-3) = 0.13%, so the mean and SD of
# the drawn sigmas are close matching sampled values.
# x axis: both parameters are > 0, so each panel starts at 0 (lab rule) and runs
# 20% of the range past the largest draw / reference value.

true_population <- readRDS(file.path(artifacts_dir, "true_population.rds"))
true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))

hyperparams <- true_population$parameter
sessions    <- paste0("session", 1:n_sessions)

sample_stat_df <- tibble(
  parameter   = hyperparams,
  sample_stat = c(mean(true_parameters$sigma), sd(true_parameters$sigma))
)

draws_long <- map_dfr(sessions, function(session) {
  readRDS(file.path(artifacts_dir, paste0("draws_", session, ".rds"))) |>
    subset_draws(hyperparams) |>
    as_draws_df() |>
    as_tibble() |>
    select(all_of(hyperparams)) |>
    pivot_longer(everything(), names_to = "parameter", values_to = "value") |>
    mutate(session = session)
}) |>
  mutate(parameter = factor(parameter, levels = hyperparams))

hyperparameter_recovery <- draws_long |>
  group_by(session, parameter) |>
  summarise(median   = median(value),
            lower_90 = quantile(value, 0.05),
            upper_90 = quantile(value, 0.95),
            .groups  = "drop") |>
  left_join(true_population, by = join_by(parameter == parameter)) |>
  left_join(sample_stat_df, by = "parameter") |>
  mutate(population_in_90   = true_value >= lower_90 & true_value <= upper_90,
         sampled_in_90      = sample_stat >= lower_90 & sample_stat <= upper_90,
         parameter          = factor(parameter, levels = hyperparams)) |>
  select(session, parameter, population_value = true_value, sampled_value = sample_stat,
         median, lower_90, upper_90, population_in_90, sampled_in_90)

print(hyperparameter_recovery, width = Inf)

# From 0 to 20% of each parameter's range (both sessions) past its largest value,
# always including the population value and the sampled value
anchor_df <- draws_long |>
  left_join(hyperparameter_recovery, by = c("session", "parameter")) |>
  group_by(parameter) |>
  reframe(value = {
    r <- range(c(value, population_value[1], sampled_value[1]))
    c(0, r[2] + 0.20 * diff(r))
  }) |>
  expand_grid(session = sessions)

p_hyperparameter_recovery <- ggplot(draws_long, aes(x = value, y = 0)) +
  stat_slab(fill = "gray80") +
  stat_pointinterval(aes(linewidth = after_stat(-.width)), .width = c(0.80, 0.90), point_size = 3) +
  scale_linewidth_continuous(range = c(1, 2), guide = "none") +
  geom_vline(data = hyperparameter_recovery,
             aes(xintercept = population_value, colour = "Population value", linetype = "Population value"),
             linewidth = 0.7) +
  geom_vline(data = hyperparameter_recovery,
             aes(xintercept = sampled_value, colour = "Sampled value", linetype = "Sampled value"),
             linewidth = 0.7) +
  geom_vline(data = hyperparameter_recovery,
             aes(xintercept = median, colour = "Posterior median", linetype = "Posterior median"),
             linewidth = 0.4) +
  geom_text(data = hyperparameter_recovery,
            aes(x = median, y = Inf, label = sprintf("[median = %.2f]", median)),
            inherit.aes = FALSE, hjust = -0.05, vjust = 1.4, size = 3, colour = "grey40") +
  geom_blank(data = anchor_df, aes(x = value, y = 0)) +
  facet_grid(session ~ parameter, scales = "free_x") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.02))) +
  scale_colour_manual(values = c("Population value" = "#4477AA", "Sampled value" = "#EE6677",
                                 "Posterior median" = "grey65")) +
  scale_linetype_manual(values = c("Population value" = "dashed", "Sampled value" = "solid",
                                   "Posterior median" = "dashed")) +
  theme_minimal(base_size = 13) +
  theme(panel.grid = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank(),
        axis.ticks.y = element_blank(), axis.line.x = element_line(colour = "grey30"),
        legend.position = "bottom", panel.spacing.x = unit(1.5, "lines")) +
  labs(x = "Posterior value", colour = NULL, linetype = NULL) +
  coord_cartesian(clip = "off")

ggsave(file.path(output_dir, "hyperparameter_recovery.png"), plot = p_hyperparameter_recovery,
       width = 10, height = 6, dpi = 300, bg = "white")
ggsave(file.path(output_dir, "hyperparameter_recovery.pdf"), plot = p_hyperparameter_recovery,
       width = 10, height = 6, bg = "white")

saveRDS(p_hyperparameter_recovery, file.path(artifacts_dir, "p_hyperparameter_recovery.rds"))   # for the combined PDF
write_csv(hyperparameter_recovery, file.path(artifacts_dir, "hyperparameter_recovery.csv"))
saveRDS(hyperparameter_recovery, file.path(artifacts_dir, "hyperparameter_recovery.rds"))
