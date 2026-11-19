#### WHERE DOES THE DIFFERENCE COME FROM? PER SESSION AND PER PARTICIPANT ####
# The pointwise elpd_loo of each trial is summed per wave and per participant-session.
# elpd_diff = halfnormal minus lognormal (positive = the half-normal model predicts the
# held-out trials better).
# Standard error of a summed difference: sd(trial differences) * sqrt(n trials), as in loo_compare.
# Pareto k > k_threshold marks trials whose LOO estimate is unreliable.
# The two models differ only in the population distribution of beta, so the per-session
# difference is plotted against beta (posterior median from each model).

model_a <- names(models)[1]   # lognormal (reference)
model_b <- names(models)[2]   # halfnormal
diff_label <- paste(model_b, "minus", model_a)

df_pointwise <- trial_index |>
  mutate(elpd_a = loo_list[[model_a]]$pointwise[, "elpd_loo"],
         elpd_b = loo_list[[model_b]]$pointwise[, "elpd_loo"],
         k_a    = loo_list[[model_a]]$diagnostics$pareto_k,
         k_b    = loo_list[[model_b]]$diagnostics$pareto_k,
         diff   = elpd_b - elpd_a)

share_col_a <- paste0("share_k_gt_threshold_", model_a)
share_col_b <- paste0("share_k_gt_threshold_", model_b)

summarise_diff <- function(d) d |>
  summarise(n_trials  = n(),
            elpd_diff = sum(diff),
            se_diff   = sd(diff) * sqrt(n()),
            !!share_col_a := mean(k_a > k_threshold),
            !!share_col_b := mean(k_b > k_threshold),
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

# Per participant-session, with beta and tau (posterior medians) from both models
read_params <- function(model) {
  read_csv(file.path(models[[model]]$dir, "participant_parameters.csv"), show_col_types = FALSE) |>
    select(prolific_id, time, beta, tau) |>
    rename_with(\(x) paste0(x, "_", model), c(beta, tau))
}
df_params <- read_params(model_a) |>
  full_join(read_params(model_b), by = c("prolific_id", "time"))

df_session <- df_pointwise |>
  group_by(prolific_id, time) |>
  summarise_diff() |>
  left_join(df_params, by = c("prolific_id", "time")) |>
  mutate(flagged = .data[[share_col_a]] > flag_share | .data[[share_col_b]] > flag_share)

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

cat("\nParticipant-sessions where", model_b, "has higher elpd:", sum(df_session$elpd_diff > 0), "of", nrow(df_session),
    "\n  ... by more than 2 SE:", sum(df_session$elpd_diff > 2 * df_session$se_diff),
    "\n ", model_a, "higher by more than 2 SE:", sum(df_session$elpd_diff < -2 * df_session$se_diff), "\n")

#### PLOTS ####

base_theme <- theme_bw() + theme(panel.grid.minor = element_blank())
log_breaks <- c(0.5, 1, 2, 5, 10, 20, 50)
flag_shapes <- scale_shape_manual(
  values = c(`FALSE` = 16, `TRUE` = 4),
  labels = c(`FALSE` = "reliable LOO",
             `TRUE`  = sprintf("flagged (>%d%% of trials k > %.1f)", 100 * flag_share, k_threshold)),
  name = NULL
)

# A: distribution of the per-session difference
p_hist <- df_session |>
  ggplot(aes(x = elpd_diff)) +
  geom_histogram(bins = 50, fill = "grey55", colour = "white", linewidth = 0.4) +
  geom_vline(xintercept = 0, colour = "grey15") +
  labs(title = "A. elpd difference per participant-session",
       subtitle = sprintf("%s. Positive in %d of %d sessions; total %+.1f (SE %.1f).",
                          diff_label, sum(df_session$elpd_diff > 0), nrow(df_session),
                          sum(df_pointwise$diff), sd(df_pointwise$diff) * sqrt(nrow(df_pointwise))),
       x = "elpd_loo difference (sum over the session's 105 trials)", y = "Participant-sessions") +
  base_theme

# B: difference against the session's beta (reference model)
p_beta <- df_session |>
  ggplot(aes(x = .data[[paste0("beta_", model_a)]], y = elpd_diff)) +
  geom_hline(yintercept = 0, colour = "grey50") +
  geom_linerange(aes(ymin = elpd_diff - 2 * se_diff, ymax = elpd_diff + 2 * se_diff), colour = "grey70", linewidth = 0.3) +
  geom_point(aes(shape = flagged), size = 2, alpha = 0.75, colour = "grey20") +
  flag_shapes +
  scale_x_log10(breaks = log_breaks, labels = as.character(log_breaks)) +
  labs(title = "B. elpd difference against the session's beta",
       subtitle = "Point: session total. Line: +/- 2 SE.",
       x = sprintf("beta (posterior median, %s model; log axis)", model_a),
       y = sprintf("elpd_loo difference (%s)", diff_label)) +
  base_theme +
  theme(legend.position = "bottom")

# C: how much the two models disagree on each session's beta
p_beta_agreement <- df_session |>
  ggplot(aes(x = .data[[paste0("beta_", model_a)]], y = .data[[paste0("beta_", model_b)]])) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "grey50") +
  geom_point(aes(colour = elpd_diff), size = 2, alpha = 0.85) +
  scale_colour_gradient2(low = "#B2182B", mid = "grey85", high = "#2166AC", midpoint = 0,
                         name = sprintf("elpd diff\n(%s)", diff_label)) +
  scale_x_log10(breaks = log_breaks, labels = as.character(log_breaks)) +
  scale_y_log10(breaks = log_breaks, labels = as.character(log_breaks)) +
  labs(title = "C. beta in the two models",
       subtitle = "Posterior medians per participant-session. Dashed: equal.",
       x = sprintf("beta, %s model (log axis)", model_a),
       y = sprintf("beta, %s model (log axis)", model_b)) +
  base_theme +
  theme(legend.position = "bottom")

p_session <- p_hist + p_beta + p_beta_agreement

pdf(file.path(output_dir, "elpd_diff_per_participant_session.pdf"), width = 19, height = 6.5)
print(p_session)
dev.off()
ggsave(file.path(output_dir, "elpd_diff_per_participant_session.png"), p_session, width = 19, height = 6.5, dpi = 130)
