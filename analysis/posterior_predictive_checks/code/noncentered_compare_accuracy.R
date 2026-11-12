#### COMPARE THE TWO MODELS' ACCURACY ####
# Per participant:
#   diff_ppa   = posterior predictive accuracy of beta_tau_rho minus beta_tau (mean over draws), with a
#                90% interval from the draw-wise differences (draw d of one fit paired with draw d of the
#                other; the fits are independent, so the interval also carries the sampling noise of
#                both models' predicted responses).
#   diff_best  = best-guess accuracy, beta_tau_rho minus beta_tau.
#   agreement  = share of trials on which the two models' best guesses are the same response
#                (how differently the two models predict, regardless of who is right).
#   rho_mean   = posterior mean of rho (beta_tau_rho), averaged over the participant's sessions.

lab_base <- model_labels[["base"]]
lab_rho  <- model_labels[["rho"]]

df_draw_diff <- df_draw_accuracy |>
  pivot_wider(names_from = model, values_from = accuracy) |>
  mutate(diff = .data[[lab_rho]] - .data[[lab_base]])

df_agreement <- df_trial_best |>
  select(model, time, prolific_id, trial, best_guess) |>
  pivot_wider(names_from = model, values_from = best_guess) |>
  group_by(prolific_id) |>
  summarise(agreement = mean(.data[[lab_base]] == .data[[lab_rho]]), .groups = "drop")

df_rho <- map_dfr(waves, \(w) {
  tibble(prolific_id = obs_data[[w]]$lookup$prolific_id, rho = colMeans(draws_by_model$rho[[w]]$rho))
}) |>
  group_by(prolific_id) |>
  summarise(rho_mean = mean(rho), .groups = "drop")

df_compare <- df_accuracy_participant |>
  select(model, prolific_id, n_trials, n_skips, ppa_mean, best_guess_acc) |>
  pivot_wider(names_from = model, values_from = c(ppa_mean, best_guess_acc)) |>
  left_join(df_draw_diff |>
              group_by(prolific_id) |>
              summarise(diff_ppa      = mean(diff),
                        diff_ppa_q05  = quantile(diff, 0.05, names = FALSE),
                        diff_ppa_q95  = quantile(diff, 0.95, names = FALSE),
                        p_rho_better  = mean(diff > 0),
                        .groups = "drop"),
            by = "prolific_id") |>
  mutate(diff_best = .data[[paste0("best_guess_acc_", lab_rho)]] - .data[[paste0("best_guess_acc_", lab_base)]]) |>
  left_join(df_agreement, by = "prolific_id") |>
  left_join(df_rho, by = "prolific_id") |>
  mutate(across(where(is.double), \(x) round(x, 4)))

write_csv(df_compare, file.path(output_dir, "accuracy_model_comparison_per_participant.csv"))

# Summary of the comparison
df_group_diff <- df_draw_diff |>
  group_by(draw) |>
  summarise(group_diff = mean(diff), .groups = "drop")

df_compare_summary <- tibble(
  participants                     = nrow(df_compare),
  mean_diff_ppa                    = mean(df_compare$diff_ppa),
  group_diff_ppa_q05               = quantile(df_group_diff$group_diff, 0.05, names = FALSE),
  group_diff_ppa_q95               = quantile(df_group_diff$group_diff, 0.95, names = FALSE),
  median_diff_ppa                  = median(df_compare$diff_ppa),
  n_rho_higher_ppa                 = sum(df_compare$diff_ppa > 0),
  n_base_higher_ppa                = sum(df_compare$diff_ppa < 0),
  n_rho_higher_90                  = sum(df_compare$diff_ppa_q05 > 0),
  n_base_higher_90                 = sum(df_compare$diff_ppa_q95 < 0),
  mean_diff_best                   = mean(df_compare$diff_best),
  n_rho_higher_best                = sum(df_compare$diff_best > 0),
  n_equal_best                     = sum(df_compare$diff_best == 0),
  n_base_higher_best               = sum(df_compare$diff_best < 0),
  mean_agreement                   = mean(df_compare$agreement),
  min_agreement                    = min(df_compare$agreement),
  cor_ppa_between_models           = cor(df_compare[[paste0("ppa_mean_", lab_base)]], df_compare[[paste0("ppa_mean_", lab_rho)]]),
  cor_diff_ppa_with_rho            = cor(df_compare$diff_ppa, df_compare$rho_mean)
) |>
  mutate(across(where(is.double), \(x) round(x, 4)))

write_csv(df_compare_summary, file.path(output_dir, "accuracy_model_comparison_summary.csv"))
print(pivot_longer(df_compare_summary, everything(), values_transform = as.character), n = Inf)

#### COMPARISON PLOTS ####

base_theme <- theme_bw() + theme(panel.grid.minor = element_blank())

# 1. The two histograms on a shared x-axis
df_medians <- df_accuracy_participant |> group_by(model) |> summarise(med = median(ppa_mean), .groups = "drop")
p_both <- df_accuracy_participant |>
  ggplot(aes(x = ppa_mean, fill = model)) +
  geom_histogram(breaks = acc_breaks, colour = "white", linewidth = 0.5) +
  geom_vline(data = df_medians, aes(xintercept = med), colour = "grey15", linewidth = 0.6) +
  geom_vline(xintercept = 1 / 3, linetype = "dashed", colour = "grey45") +
  facet_wrap(~ model, ncol = 1) +
  scale_fill_manual(values = model_colors, guide = "none") +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 1)) +
  labs(title = "A. Posterior predictive accuracy per participant",
       subtitle = "Solid line: median participant. Dashed: chance (1/3).",
       x = "Posterior predictive accuracy", y = "Participants") +
  base_theme

# 2. Participant by participant
p_scatter <- df_compare |>
  ggplot(aes(x = .data[[paste0("ppa_mean_", lab_base)]], y = .data[[paste0("ppa_mean_", lab_rho)]])) +
  geom_abline(slope = 1, intercept = 0, colour = "grey50") +
  geom_point(size = 2, alpha = 0.7, colour = "grey20") +
  coord_equal() +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(title = "B. Same participant, two models",
       subtitle = "Above the line: beta_tau_rho predicts better",
       x = paste("Accuracy,", lab_base), y = paste("Accuracy,", lab_rho)) +
  base_theme

# 3. Distribution of the per-participant difference
p_diff <- df_compare |>
  ggplot(aes(x = diff_ppa)) +
  geom_histogram(bins = 40, fill = "grey55", colour = "white", linewidth = 0.4) +
  geom_vline(xintercept = 0, colour = "grey15") +
  geom_vline(xintercept = median(df_compare$diff_ppa), linetype = "dashed", colour = model_colors[[lab_rho]], linewidth = 0.7) +
  scale_x_continuous(labels = scales::label_number(scale = 100, suffix = " pp")) +
  labs(title = "C. Difference in accuracy (beta_tau_rho minus beta_tau)",
       subtitle = sprintf("Dashed: median participant (%+.1f pp). Higher for beta_tau_rho in %d of %d participants.",
                          100 * median(df_compare$diff_ppa), sum(df_compare$diff_ppa > 0), nrow(df_compare)),
       x = "Accuracy difference (percentage points)", y = "Participants") +
  base_theme

# 4. Where rho helps: difference against the participant's rho
p_diff_rho <- df_compare |>
  ggplot(aes(x = rho_mean, y = diff_ppa)) +
  geom_hline(yintercept = 0, colour = "grey50") +
  geom_linerange(aes(ymin = diff_ppa_q05, ymax = diff_ppa_q95), colour = "grey70", linewidth = 0.3) +
  geom_point(size = 2, alpha = 0.7, colour = "grey20") +
  scale_y_continuous(labels = scales::label_number(scale = 100, suffix = " pp")) +
  labs(title = "D. Accuracy gain against the participant's rho",
       subtitle = "Point: mean difference. Line: 90% interval over draws.",
       x = "Posterior mean rho (beta_tau_rho, mean of the two sessions)",
       y = "Accuracy difference (beta_tau_rho minus beta_tau)") +
  base_theme

p_compare <- (p_both | p_scatter) / (p_diff | p_diff_rho)

# 5. How often the two models make the same best guess
p_agree <- df_compare |>
  ggplot(aes(x = agreement)) +
  geom_histogram(breaks = seq(0, 1, 0.025), fill = "grey55", colour = "white", linewidth = 0.4) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0, 1)) +
  labs(title = "How differently the two models predict",
       subtitle = sprintf("Share of trials on which both models' most probable response is the same (mean %.1f%%)",
                          100 * mean(df_compare$agreement)),
       x = "Agreement between the models' best guesses", y = "Participants") +
  base_theme

# 6. Best-guess accuracy, participant by participant
p_best_scatter <- df_compare |>
  ggplot(aes(x = .data[[paste0("best_guess_acc_", lab_base)]], y = .data[[paste0("best_guess_acc_", lab_rho)]])) +
  geom_abline(slope = 1, intercept = 0, colour = "grey50") +
  geom_point(size = 2, alpha = 0.7, colour = "grey20") +
  coord_equal() +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(title = "Best-guess accuracy, same participant, two models",
       x = paste("Best-guess accuracy,", lab_base), y = paste("Best-guess accuracy,", lab_rho)) +
  base_theme

pdf(file.path(output_dir, "accuracy_model_comparison.pdf"), width = 13, height = 11)
print(p_compare)
print(p_agree | p_best_scatter)
dev.off()
ggsave(file.path(output_dir, "accuracy_model_comparison.png"), p_compare, width = 13, height = 11, dpi = 130)
