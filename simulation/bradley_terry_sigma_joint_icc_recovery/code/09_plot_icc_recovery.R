#### FIGURE 3: ICC RECOVERY ACROSS RUNS ####
# reads:  artifacts/recovery_population.rds
# writes: output/09_icc_recovery.{pdf,png}, output/09_icc_recovery.csv, artifacts/figure_3.rds
#
# One point per ICC per run (3 runs x sigma, item profile, tau): true ICC (x) vs posterior median
# (y) with its 95% interval. Panels: consistency and agreement. [0, 1] on both axes, identity
# line dashed. The table lists every ICC with its true value, interval and coverage.

recovery_population <- readRDS(file.path(artifacts_dir, "recovery_population.rds"))

icc_parameters <- tribble(
  ~parameter,      ~quantity,                ~type,
  "icc_sigma",     "sigma",                  "Consistency",
  "icc_A_sigma",   "sigma",                  "Agreement",
  "icc_profile_C", "Item profile (15 items)", "Consistency",
  "icc_profile_A", "Item profile (15 items)", "Agreement",
  "icc_tau",       "tau (None)",             "Consistency",
  "icc_A_tau",     "tau (None)",             "Agreement"
) |>
  mutate(quantity = factor(quantity, levels = unique(quantity)),
         type     = factor(type, levels = c("Consistency", "Agreement")))

icc_recovery_table <- recovery_population |>
  inner_join(icc_parameters, by = "parameter") |>
  mutate(run_label = run_labels[run]) |>
  select(run, run_label, quantity, type, parameter, true_value, median, lower, upper, covered) |>
  arrange(quantity, type, run)
print(icc_recovery_table, n = Inf, width = Inf)
write_csv(icc_recovery_table, file.path(output_dir, "09_icc_recovery.csv"))

df_labels <- icc_recovery_table |>
  group_by(type) |>
  summarise(label = sprintf("[coverage = %d/%d]", sum(covered), n()))

pal_quantity <- c("sigma" = "#4477AA", "Item profile (15 items)" = "#228833", "tau (None)" = "#EE6677")

figure_3 <- ggplot(icc_recovery_table, aes(x = true_value, y = median, colour = quantity)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0, linewidth = 0.8, alpha = 0.7,
                position = position_dodge(width = 0.02)) +
  geom_point(size = 2.5, position = position_dodge(width = 0.02)) +
  geom_text(data = df_labels, aes(x = 0.02, y = 0.98, label = label), inherit.aes = FALSE,
            hjust = 0, vjust = 1, size = 3.5, colour = "grey30") +
  facet_wrap(~ type) +
  scale_colour_manual(values = pal_quantity, name = NULL) +
  scale_x_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), labels = c("0", "0.25", "0.5", "0.75", "1")) +
  scale_y_continuous(breaks = c(0, 0.25, 0.5, 0.75, 1), labels = c("0", "0.25", "0.5", "0.75", "1")) +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank(), legend.position = "top") +
  labs(x = "True ICC", y = "Posterior median ICC (95% interval)")

saveRDS(figure_3, file.path(artifacts_dir, "figure_3.rds"))
plot_name <- "09_icc_recovery"
ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = figure_3, width = 10, height = 6, bg = "white")
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = figure_3, width = 10, height = 6, dpi = 300, bg = "white")
