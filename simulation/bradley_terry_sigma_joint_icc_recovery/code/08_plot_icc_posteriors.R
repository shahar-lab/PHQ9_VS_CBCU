#### FIGURE 2: ICC POSTERIORS (SIGMA, ITEM PROFILE, TAU) ####
# reads:  artifacts/<run>/draws_pop.rds, artifacts/recovery_population.rds
# writes: output/08_icc_posteriors.{pdf,png}, artifacts/figure_2.rds
#
# Columns: ICC of sigma, profile ICC of the 15 items (Hypothesis 1; agreement = eq. [2]), ICC of
# tau. Rows: runs. Consistency and agreement overlaid, each slab scaled to its own maximum,
# 90% interval; true values as dotted lines in the matching colour. ICCs on [0, 1].

recovery_population <- readRDS(file.path(artifacts_dir, "recovery_population.rds"))
pal_icc <- c("Consistency" = "#228833", "Agreement" = "#EE6677")

icc_parameters <- tribble(
  ~parameter,      ~quantity,          ~type,
  "icc_sigma",     "ICC of sigma",     "Consistency",
  "icc_A_sigma",   "ICC of sigma",     "Agreement",
  "icc_profile_C", "Profile ICC (15 items)", "Consistency",
  "icc_profile_A", "Profile ICC (15 items)", "Agreement",
  "icc_tau",       "ICC of tau",       "Consistency",
  "icc_A_tau",     "ICC of tau",       "Agreement"
) |>
  mutate(quantity = factor(quantity, levels = unique(quantity)),
         type     = factor(type, levels = names(pal_icc)))

df_draws <- map(run_names, \(run) {
  readRDS(file.path(artifacts_dir, run, "draws_pop.rds")) |>
    as_tibble() |>
    select(all_of(icc_parameters$parameter)) |>
    pivot_longer(everything(), names_to = "parameter", values_to = "value") |>
    mutate(run = run)
}) |>
  list_rbind() |>
  left_join(icc_parameters, by = "parameter")

df_true <- recovery_population |>
  select(run, parameter, true_value) |>
  inner_join(icc_parameters, by = "parameter")

figure_2 <- ggplot(df_draws, aes(x = value, y = 0, fill = type, colour = type)) +
  stat_slab(alpha = 0.5, normalize = "groups") +
  stat_pointinterval(.width = 0.90, point_size = 2, position = position_dodge(width = 0.2)) +
  geom_vline(data = df_true, aes(xintercept = true_value, colour = type), linetype = "dotted", linewidth = 0.8) +
  facet_grid(run ~ quantity, labeller = labeller(run = setNames(str_wrap(run_labels, 22), names(run_labels)))) +
  scale_fill_manual(values = pal_icc, name = NULL) +
  scale_colour_manual(values = pal_icc, guide = "none") +
  scale_x_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), labels = c("0", "0.25", "0.5", "0.75", "1")) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1.1)) +
  theme_minimal(base_size = 13) +
  theme(panel.grid = element_blank(), axis.title.y = element_blank(), axis.text.y = element_blank(),
        axis.ticks.y = element_blank(), axis.line.x = element_line(colour = "grey30"),
        legend.position = "top", strip.text.y = element_text(angle = 0, hjust = 0)) +
  labs(x = "ICC")

saveRDS(figure_2, file.path(artifacts_dir, "figure_2.rds"))
plot_name <- "08_icc_posteriors"
ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = figure_2, width = 12, height = 7, bg = "white")
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = figure_2, width = 12, height = 7, dpi = 300, bg = "white")
