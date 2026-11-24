#### COMPUTE CHOICE PREDICTION ####
# reads: artifacts/draws_<session>.rds, simulated_data.rds
# writes: artifacts/trial_choice_prediction.rds, choice_prediction_by_subject.csv / .rds
#
# Choice prediction of a trial = the model's probability of the option the
# participant actually chose (A, B or None), under the 3-way softmax over A, B and
# None (logits u[A], u[B], tau = u[None]), averaged over posterior draws.
# Per participant per session, two means:
#   choice_prediction     : over trials where A or B was chosen ("None" skipped)
#   choice_prediction_all : over all trials, None included

df_simulated <- readRDS(file.path(artifacts_dir, "simulated_data.rds"))

sessions <- paste0("session", 1:n_sessions)

# log(exp(a) + exp(b) + exp(c)), element-wise, without overflow
log_sum_exp3 <- function(a, b, c) {
  m <- pmax(a, b, c)
  m + log(exp(a - m) + exp(b - m) + exp(c - m))
}

df_trial_prediction <- map_dfr(sessions, function(this_session) {

  draws <- readRDS(file.path(artifacts_dir, paste0("draws_", this_session, ".rds")))

  df_session <- filter(df_simulated, session == this_session)

  map_dfr(split(df_session, df_session$subject), function(df_subject) {

    s <- df_subject$subject[1]

    tau_s <- as.vector(draws[, sprintf("tau[%d]", s)])   # one value per draw
    u_s   <- unclass(draws[, sprintf("u_matrix[%d,%d]", s, 1:n_options)])   # draws x items

    n_draws <- length(tau_s)
    n_trial <- nrow(df_subject)

    # draws x trials matrices of logits (no beta: the utilities are the logits)
    eta_A    <- u_s[, df_subject$offer_A, drop = FALSE]
    eta_B    <- u_s[, df_subject$offer_B, drop = FALSE]
    eta_None <- matrix(tau_s, nrow = n_draws, ncol = n_trial)

    chose_A    <- matrix(df_subject$choice == "A", nrow = n_draws, ncol = n_trial, byrow = TRUE)
    chose_B    <- matrix(df_subject$choice == "B", nrow = n_draws, ncol = n_trial, byrow = TRUE)
    eta_chosen <- ifelse(chose_A, eta_A, ifelse(chose_B, eta_B, eta_None))

    prob_chosen <- exp(eta_chosen - log_sum_exp3(eta_A, eta_B, eta_None))

    df_subject |>
      transmute(session, subject, trial, choice,
                prob_chosen      = colMeans(prob_chosen),
                true_prob_chosen = case_when(choice == "A" ~ prob_A,
                                             choice == "B" ~ prob_B,
                                             TRUE          ~ prob_None))
  })
})

# A participant with a high tau can choose None on every trial of a session.
# They have no A/B trials, so their A/B choice prediction is NA (n_trials_AB = 0).
df_choice_prediction <- df_trial_prediction |>
  group_by(session, subject) |>
  summarise(choice_prediction          = mean(prob_chosen[choice != "None"]),
            true_choice_prediction     = mean(true_prob_chosen[choice != "None"]),
            n_trials_AB                = sum(choice != "None"),
            choice_prediction_all      = mean(prob_chosen),
            true_choice_prediction_all = mean(true_prob_chosen),
            n_trials                   = n(),
            .groups = "drop") |>
  mutate(across(c(choice_prediction, true_choice_prediction), \(x) if_else(is.nan(x), NA_real_, x)))

stopifnot(nrow(df_choice_prediction) == n_subjects * n_sessions,
          all(between(df_choice_prediction$choice_prediction, 0, 1), na.rm = TRUE),
          all(between(df_choice_prediction$choice_prediction_all, 0, 1)))

print(filter(df_choice_prediction, n_trials_AB == 0))

saveRDS(df_trial_prediction, file.path(artifacts_dir, "trial_choice_prediction.rds"))
write_csv(df_choice_prediction, file.path(artifacts_dir, "choice_prediction_by_subject.csv"))
saveRDS(df_choice_prediction, file.path(artifacts_dir, "choice_prediction_by_subject.rds"))
