#### FIGURE 4: INDIVIDUAL RECOVERY (SIGMA, TAU, ITEM UTILITIES PER UNIT) ####
# reads:  artifacts/recovered_parameters.rds
# writes: output/10_individual_recovery.{pdf,png}, output/10_individual_recovery.csv, artifacts/figure_4.rds
#
# One point per unit (participant x session); items pooled over the 15 utilities. True (x) vs
# posterior median (y), OLS line, identity line, Pearson r; x and y share each panel's range.
# Table: r, bias (mean median - true), OLS slope, median posterior SD, 95% coverage, and the
# correlation of sigma and tau errors (a trade-off between the two would show here).

recovered_parameters <- readRDS(file.path(artifacts_dir, "recovered_parameters.rds"))

df <- recovered_parameters |>
  mutate(parameter = if_else(str_detect(parameter, "^u_"), "Item utilities", parameter),
         parameter = factor(parameter, levels = c("sigma", "tau", "Item utilities")))

error_correlation <- recovered_parameters |>
  filter(parameter %in% c("sigma", "tau")) |>
  mutate(error = median - true_value) |>
  select(run, unit, parameter, error) |>
  pivot_wider(names_from = parameter, values_from = error) |>
  group_by(run) |>
  summarise(r_error_sigma_tau = cor(sigma, tau))

individual_table <- df |>
  group_by(run, parameter) |>
  summarise(pearson_r        = cor(true_value, median),
            mean_bias        = mean(median - true_value),
            ols_slope        = coef(lm(median ~ true_value))[2],
            median_posterior_sd = median(sd),
            coverage_95      = mean(true_value >= lower & true_value <= upper),
            true_range       = diff(range(true_value)),
            recovered_range  = diff(range(median)),
            .groups = "drop") |>
  left_join(error_correlation, by = "run")
print(individual_table, width = Inf)
write_csv(individual_table, file.path(output_dir, "10_individual_recovery.csv"))

df_labels <- individual_table |> mutate(label = sprintf("[Pearson r = %.2f]", pearson_r))

figure_4 <- ggplot(df, aes(x = true_value, y = median)) +
  geom_blank(aes(x = median, y = true_value)) +   # same range on x and y in every panel
  geom_point(colour = "#4477AA", alpha = 0.3, size = 1) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, colour = "#EE6677", linewidth = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey60", linewidth = 0.6) +
  geom_text(data = df_labels, aes(x = Inf, y = Inf, label = label),
            hjust = 1.05, vjust = 1.4, size = 3.2, colour = "grey30") +
  facet_wrap(run ~ parameter, scales = "free", ncol = 3,
             labeller = labeller(run = setNames(sprintf("Run %d", seq_along(run_labels)), names(run_labels)),
                                 .multi_line = FALSE)) +   # full run labels are in the caption
  theme_minimal(base_size = 13) +
  theme(panel.grid.minor = element_blank(), aspect.ratio = 1) +
  labs(x = "True value", y = "Posterior median")

saveRDS(figure_4, file.path(artifacts_dir, "figure_4.rds"))
plot_name <- "10_individual_recovery"
ggsave(file.path(output_dir, paste0(plot_name, ".pdf")), plot = figure_4, width = 10, height = 10, bg = "white")
ggsave(file.path(output_dir, paste0(plot_name, ".png")), plot = figure_4, width = 10, height = 10, dpi = 300, bg = "white")
