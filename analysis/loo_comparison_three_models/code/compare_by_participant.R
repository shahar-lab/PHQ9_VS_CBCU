#### WHERE DOES THE DIFFERENCE COME FROM? PER SESSION AND PER PARTICIPANT ####
# The pointwise elpd_loo of each trial is summed per wave and per participant-session.
# elpd_diff = beta_tau_rho minus beta_tau (positive = rho predicts the held-out trials better).
# Standard error of a summed difference: sd(trial differences) * sqrt(n trials), as in loo_compare.
# Pareto k > k_threshold marks trials whose LOO estimate is unreliable.

model_a <- names(models)[1]   # beta_tau
model_b <- names(models)[2]   # beta_tau_rho

df_pointwise <- trial_index |>
  mutate(elpd_a = loo_list[[model_a]]$pointwise[, "elpd_loo"],
         elpd_b = loo_list[[model_b]]$pointwise[, "elpd_loo"],
         k_a    = loo_list[[model_a]]$diagnostics$pareto_k,
         k_b    = loo_list[[model_b]]$diagnostics$pareto_k,
         diff   = elpd_b - elpd_a)

summarise_diff <- function(d) d |>
  summarise(n_trials  = n(),
            elpd_diff = sum(diff),
            se_diff   = sd(diff) * sqrt(n()),
            share_k_gt_threshold_beta_tau     = mean(k_a > k_threshold),
            share_k_gt_threshold_beta_tau_rho = mean(k_b > k_threshold),
            .groups = "drop")

# Per wave and overall
df_by_wave <- bind_rows(
  df_pointwise |> group_by(time) |> summarise_diff(),
  df_pointwise |> mutate(time = "both waves") |> group_by(time) |> summarise_diff()
) |>
  mutate(z = elpd_diff / se_diff)
write_csv(df_by_wave |> mutate(across(where(is.double), \(x) round(x, 3))),
          file.path(output_dir, "elpd_diff_by_wave.csv"))
print(df_by_wave)

# Per participant-session, with the session's rho estimate (posterior median) and skip count
df_rho <- read_csv(file.path(models[[model_b]]$dir, "participant_parameters.csv"), show_col_types = FALSE) |>
  select(prolific_id, time, beta, tau, rho)

df_session <- df_pointwise |>
  group_by(prolific_id, time) |>
  summarise_diff() |>
  left_join(df_rho, by = c("prolific_id", "time")) |>
  mutate(flagged = share_k_gt_threshold_beta_tau > flag_share | share_k_gt_threshold_beta_tau_rho > flag_share)

write_csv(df_session |> mutate(across(where(is.double), \(x) round(x, 4))),
          file.path(output_dir, "elpd_diff_per_participant_session.csv"))

# The comparison restricted to sessions without many unreliable trials (sensitivity check)
df_by_flag <- df_pointwise |>
  left_join(select(df_session, prolific_id, time, flagged), by = c("prolific_id", "time")) |>
  group_by(subset = if_else(flagged, "flagged sessions", "not flagged")) |>
  summarise_diff() |>
  mutate(n_sessions = n_trials / 105, z = elpd_diff / se_diff)
write_csv(df_by_flag |> mutate(across(where(is.double), \(x) round(x, 3))),
          file.path(output_dir, "elpd_diff_by_pareto_k_flag.csv"))
print(df_by_flag)

cat("\nParticipant-sessions where beta_tau_rho has higher elpd:", sum(df_session$elpd_diff > 0), "of", nrow(df_session),
    "\n  ... by more than 2 SE:", sum(df_session$elpd_diff > 2 * df_session$se_diff),
    "\n  beta_tau higher by more than 2 SE:", sum(df_session$elpd_diff < -2 * df_session$se_diff), "\n")

#### PLOTS ####

base_theme <- theme_bw() + theme(panel.grid.minor = element_blank())

p_hist <- df_session |>
  ggplot(aes(x = elpd_diff)) +
  geom_histogram(bins = 50, fill = "grey55", colour = "white", linewidth = 0.4) +
  geom_vline(xintercept = 0, colour = "grey15") +
  labs(title = "A. elpd difference per participant-session",
       subtitle = sprintf("beta_tau_rho minus beta_tau. Positive in %d of %d sessions; total %+.1f (SE %.1f).",
                          sum(df_session$elpd_diff > 0), nrow(df_session),
                          sum(df_pointwise$diff), sd(df_pointwise$diff) * sqrt(nrow(df_pointwise))),
       x = "elpd_loo difference (sum over the session's 105 trials)", y = "Participant-sessions") +
  base_theme

p_rho <- df_session |>
  ggplot(aes(x = rho, y = elpd_diff)) +
  geom_hline(yintercept = 0, colour = "grey50") +
  geom_linerange(aes(ymin = elpd_diff - 2 * se_diff, ymax = elpd_diff + 2 * se_diff), colour = "grey70", linewidth = 0.3) +
  geom_point(aes(shape = flagged), size = 2, alpha = 0.75, colour = "grey20") +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 4),
                     labels = c(`FALSE` = "reliable LOO", `TRUE` = sprintf("flagged (>%d%% of trials k > %.1f)", 100 * flag_share, k_threshold)),
                     name = NULL) +
  labs(title = "B. elpd difference against the session's rho",
       subtitle = "Point: session total. Line: +/- 2 SE.",
       x = "rho (posterior median, beta_tau_rho)", y = "elpd_loo difference (beta_tau_rho minus beta_tau)") +
  base_theme +
  theme(legend.position = "bottom")

pdf(file.path(output_dir, "elpd_diff_per_participant_session.pdf"), width = 13, height = 6)
print(p_hist + p_rho)
dev.off()
ggsave(file.path(output_dir, "elpd_diff_per_participant_session.png"), p_hist + p_rho, width = 13, height = 6, dpi = 130)
