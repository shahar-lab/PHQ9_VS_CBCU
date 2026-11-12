#### POSTERIOR PREDICTIVE ACCURACY PER PARTICIPANT ####
# For every posterior draw, participant-session and trial, the model's probabilities of A, B and None
# are computed exactly as in the Stan models:
#   A:    beta * u[left]  + rho * (observed previous response was A)
#   B:    beta * u[right] + rho * (observed previous response was B)
#   None: beta * tau      + rho * (observed previous response was None)
# (rho = 0 for beta_tau; no bonus on a session's first trial.)
#
# The perseveration bonus uses the OBSERVED previous response (one-step-ahead prediction), which is
# how the model is fit and the fair test of "does the model predict the next response". The full-
# sequence simulation in main.R lets rho follow its own simulated history instead.
#
# Two accuracy measures per participant:
#   1. Posterior predictive accuracy: per draw, one response is drawn from the model's probabilities on
#      every trial; accuracy = share of trials where it equals the observed response. Over the draws this
#      gives the posterior predictive distribution of the participant's accuracy (summarised by its mean
#      and central 90% interval).
#   2. Best-guess accuracy: the single most probable response (posterior-mean probabilities) on each
#      trial; accuracy = share of trials where it equals the observed response.
# Both sessions are pooled per participant (up to 210 trials); per-session values are also kept.

predict_session <- function(par, obs) {
  n_d     <- nrow(par$beta)
  n_s     <- ncol(par$beta)
  n_t     <- ncol(obs$left)
  n_cells <- n_d * n_s

  # Cell index: draw varies fastest, matching as.vector() of a draws x subjects matrix
  d_idx <- rep(seq_len(n_d), times = n_s)
  s_idx <- rep(seq_len(n_s), each = n_d)

  beta <- as.vector(par$beta)
  tau  <- as.vector(par$tau)
  rho  <- as.vector(par$rho)

  n_correct <- numeric(n_cells)
  p_mean    <- array(NA_real_, dim = c(n_s, n_t, 3))   # posterior-mean probability of A, B, None

  for (t in seq_len(n_t)) {
    w_A <- beta * par$U[cbind(d_idx, s_idx, obs$left[s_idx, t])]
    w_B <- beta * par$U[cbind(d_idx, s_idx, obs$right[s_idx, t])]
    w_N <- beta * tau

    if (t > 1) {
      prev <- obs$choice[s_idx, t - 1]
      w_A  <- w_A + rho * (prev == 1L)
      w_B  <- w_B + rho * (prev == 2L)
      w_N  <- w_N + rho * (prev == 3L)
    }

    m   <- pmax(w_A, w_B, w_N)
    e_A <- exp(w_A - m)
    e_B <- exp(w_B - m)
    e_N <- exp(w_N - m)
    tot <- e_A + e_B + e_N
    p_A <- e_A / tot
    p_B <- e_B / tot

    # One posterior predictive response per draw
    r     <- runif(n_cells)
    y_rep <- 1L + (r > p_A) + (r > p_A + p_B)
    n_correct <- n_correct + (y_rep == obs$choice[s_idx, t])

    p_mean[, t, 1] <- colMeans(matrix(p_A, n_d, n_s))
    p_mean[, t, 2] <- colMeans(matrix(p_B, n_d, n_s))
    p_mean[, t, 3] <- colMeans(matrix(e_N / tot, n_d, n_s))
  }

  best_guess <- apply(p_mean, c(1, 2), which.max)   # subjects x trials (first on ties)

  list(n_correct  = matrix(n_correct, n_d, n_s),    # draws x subjects
       n_trials   = n_t,
       best_guess = best_guess,
       p_mean     = p_mean)
}

pred <- map(names(draws_by_model), \(m) {
  map(waves, \(w) predict_session(draws_by_model[[m]][[w]], obs_data[[w]])) |> setNames(waves)
}) |> setNames(names(draws_by_model))

# Long table: one row per model x session x participant x draw
df_draw_correct <- map_dfr(names(pred), \(m) {
  map_dfr(waves, \(w) {
    nc <- pred[[m]][[w]]$n_correct
    tibble(model       = model_labels[[m]],
           time        = w,
           prolific_id = rep(obs_data[[w]]$lookup$prolific_id, each = nrow(nc)),
           draw        = rep(seq_len(nrow(nc)), times = ncol(nc)),
           n_correct   = as.vector(nc),
           n_trials    = pred[[m]][[w]]$n_trials)
  })
})

# Posterior predictive accuracy per participant and draw, both sessions pooled
df_draw_accuracy <- df_draw_correct |>
  group_by(model, prolific_id, draw) |>
  summarise(accuracy = sum(n_correct) / sum(n_trials), .groups = "drop")

# Best-guess correctness per trial, and observed choice (for per-response-type breakdown)
df_trial_best <- map_dfr(names(pred), \(m) {
  map_dfr(waves, \(w) {
    bg  <- pred[[m]][[w]]$best_guess
    obs <- obs_data[[w]]$choice
    tibble(model       = model_labels[[m]],
           time        = w,
           prolific_id = rep(obs_data[[w]]$lookup$prolific_id, times = ncol(obs)),
           trial       = rep(seq_len(ncol(obs)), each = nrow(obs)),
           observed    = as.vector(obs),
           best_guess  = as.vector(bg))
  })
}) |>
  mutate(correct = best_guess == observed)

# Per-participant table
df_session_ppa <- df_draw_correct |>
  mutate(accuracy = n_correct / n_trials) |>
  group_by(model, prolific_id, time) |>
  summarise(acc = mean(accuracy), .groups = "drop") |>
  pivot_wider(names_from = time, values_from = acc, names_prefix = "ppa_mean_")

df_accuracy_participant <- df_draw_accuracy |>
  group_by(model, prolific_id) |>
  summarise(ppa_mean = mean(accuracy),
            ppa_q05  = quantile(accuracy, 0.05, names = FALSE),
            ppa_q95  = quantile(accuracy, 0.95, names = FALSE),
            .groups = "drop") |>
  left_join(df_session_ppa, by = c("model", "prolific_id")) |>
  left_join(df_trial_best |>
              group_by(model, prolific_id) |>
              summarise(n_sessions        = n_distinct(time),
                        n_trials          = n(),
                        n_skips           = sum(observed == 3L),
                        best_guess_acc    = mean(correct),
                        best_guess_acc_AB = mean(correct[observed < 3L]),
                        best_guess_acc_skip = if (any(observed == 3L)) mean(correct[observed == 3L]) else NA_real_,
                        .groups = "drop"),
            by = c("model", "prolific_id")) |>
  relocate(n_sessions, n_trials, n_skips, .after = prolific_id) |>
  mutate(across(c(starts_with("ppa_"), starts_with("best_guess")), \(x) round(x, 4)))

write_csv(df_accuracy_participant, file.path(output_dir, "accuracy_per_participant.csv"))

# Group-level summary per model. The group mean has a real posterior predictive interval:
# average over participants within each draw, then take quantiles over draws.
df_group_draws <- df_draw_accuracy |>
  group_by(model, draw) |>
  summarise(group_mean = mean(accuracy), .groups = "drop")

df_accuracy_summary <- df_accuracy_participant |>
  group_by(model) |>
  summarise(participants        = n(),
            ppa_median_participant = median(ppa_mean),
            ppa_min             = min(ppa_mean),
            ppa_max             = max(ppa_mean),
            best_guess_acc_mean = mean(best_guess_acc),
            best_guess_acc_median = median(best_guess_acc),
            .groups = "drop") |>
  left_join(df_group_draws |>
              group_by(model) |>
              summarise(ppa_group_mean = mean(group_mean),
                        ppa_group_mean_q05 = quantile(group_mean, 0.05, names = FALSE),
                        ppa_group_mean_q95 = quantile(group_mean, 0.95, names = FALSE),
                        .groups = "drop"),
            by = "model") |>
  relocate(starts_with("ppa_group"), .after = participants) |>
  mutate(across(where(is.double), \(x) round(x, 4)))

write_csv(df_accuracy_summary, file.path(output_dir, "accuracy_summary_by_model.csv"))
print(df_accuracy_summary, width = Inf)
