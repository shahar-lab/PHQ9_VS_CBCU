#### COMPARE THE CHOICES THEMSELVES (A / B / NONE): OBSERVED VS SIMULATED ####
# Three views, all from the same simulated sequences:
#   1. Overall proportions: share of A, B and None across all trials, observed against the simulated
#      distribution (one overall share per posterior draw, so the 90% interval is a real predictive interval).
#   2. Calibration: for every trial, the simulated probability of each outcome (share of the draws that
#      chose it) against how often that outcome was actually observed, in bins of predicted probability.
#   3. Accuracy: how often the most probable simulated outcome equals the observed one.
# Caveat for models 2 and 3: the simulated sequences carry their own perseveration history, so the
# per-trial probabilities are not the one-step-ahead probabilities given the observed history.

choice_labels <- c("A (left)", "B (right)", "None (skip)")

# Per-trial simulated probabilities
df_trial_prob <- map_dfr(names(sim_choices), \(m) {
  map_dfr(waves, \(w) {
    sim <- sim_choices[[m]][[w]]
    obs <- obs_data[[w]]$choice
    p   <- map(1:3, \(k) apply(sim == k, c(2, 3), mean))   # subjects x trials per outcome
    tibble(model = model_labels[[m]], time = w,
           subject = rep(seq_len(nrow(obs)), times = ncol(obs)),
           trial   = rep(seq_len(ncol(obs)), each = nrow(obs)),
           p_A = as.vector(p[[1]]), p_B = as.vector(p[[2]]), p_N = as.vector(p[[3]]),
           observed = as.vector(obs))
  })
})

# 1. Overall proportions
df_choice_props <- map_dfr(names(sim_choices), \(m) {
  map_dfr(waves, \(w) {
    sim <- sim_choices[[m]][[w]]
    obs <- obs_data[[w]]$choice
    map_dfr(1:3, \(k) {
      per_draw <- apply(sim == k, 1, mean)   # overall share for each posterior draw
      tibble(model = model_labels[[m]], time = w, outcome = choice_labels[k],
             observed = mean(obs == k),
             sim_median = median(per_draw),
             sim_q05 = quantile(per_draw, 0.05, names = FALSE),
             sim_q95 = quantile(per_draw, 0.95, names = FALSE))
    })
  })
})
write_csv(df_choice_props, file.path(output_dir, "ppc_choice_proportions.csv"))
print(df_choice_props |> mutate(across(where(is.numeric), \(x) round(x, 3))), n = Inf)

# 2. Calibration, in 10 equal-width bins of predicted probability
df_calibration <- df_trial_prob |>
  pivot_longer(c(p_A, p_B, p_N), names_to = "outcome", values_to = "predicted") |>
  mutate(outcome = recode(outcome, p_A = choice_labels[1], p_B = choice_labels[2], p_N = choice_labels[3]),
         occurred = as.integer(observed == match(outcome, choice_labels)),
         bin = cut(predicted, breaks = seq(0, 1, 0.1), include.lowest = TRUE)) |>
  group_by(model, outcome, bin) |>
  summarise(n_trials = n(), mean_predicted = mean(predicted), observed_rate = mean(occurred), .groups = "drop")
write_csv(df_calibration, file.path(output_dir, "ppc_choice_calibration.csv"))

# 3. Accuracy of the most probable outcome
df_accuracy <- df_trial_prob |>
  mutate(predicted_outcome = max.col(cbind(p_A, p_B, p_N), ties.method = "first"),
         correct = predicted_outcome == observed,
         observed_type = choice_labels[observed]) |>
  group_by(model, observed_type) |>
  summarise(n_trials = n(), share_correct = round(mean(correct), 3), .groups = "drop") |>
  bind_rows(df_trial_prob |>
              mutate(correct = max.col(cbind(p_A, p_B, p_N), ties.method = "first") == observed) |>
              group_by(model) |>
              summarise(observed_type = "all trials", n_trials = n(), share_correct = round(mean(correct), 3), .groups = "drop"))
write_csv(df_accuracy, file.path(output_dir, "ppc_choice_accuracy.csv"))
print(df_accuracy, n = Inf)

# 3b. Accuracy per participant, pooled over the two sessions (time1 + time2 = up to 210 trials).
# "Correct" = the most probable simulated outcome (A, B or None) equals the observed choice.
df_accuracy_participant <- df_trial_prob |>
  mutate(prolific_id = map2_chr(time, subject, \(w, s) obs_data[[w]]$lookup$prolific_id[s]),
         correct     = max.col(cbind(p_A, p_B, p_N), ties.method = "first") == observed) |>
  group_by(model, prolific_id) |>
  summarise(n_sessions = n_distinct(time),
            n_trials = n(),
            n_skips = sum(observed == 3L),
            accuracy = mean(correct),
            accuracy_time1 = mean(correct[time == "time1"]),
            accuracy_time2 = mean(correct[time == "time2"]),
            accuracy_AB_trials = mean(correct[observed < 3L]),
            accuracy_skip_trials = if (any(observed == 3L)) mean(correct[observed == 3L]) else NA_real_,
            .groups = "drop") |>
  mutate(across(starts_with("accuracy"), \(x) round(x, 3)))
write_csv(df_accuracy_participant, file.path(output_dir, "ppc_choice_accuracy_per_participant.csv"))

df_accuracy_participant |>
  group_by(model) |>
  summarise(participants = n(), min = min(accuracy), q25 = quantile(accuracy, 0.25), median = median(accuracy),
            q75 = quantile(accuracy, 0.75), max = max(accuracy), below_90 = sum(accuracy < 0.90), .groups = "drop") |>
  print(width = Inf)
