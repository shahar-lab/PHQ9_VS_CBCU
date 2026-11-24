#### CHOICE PREDICTION PER PARTICIPANT X DAY: POSTERIOR SUMMARY ####
# reads:  artifacts/fit_time1.rds, artifacts/fit_time2.rds,
#         artifacts/subject_lookup_time1.csv, artifacts/subject_lookup_time2.csv
# writes: artifacts/choice_prediction_icc_data.csv
#
# Choice prediction (as choice_prediction_all in
# simulation/bradley_terry_beta_tau_halfnormal_stz_recovery/code/05_compute_choice_prediction.R):
# the model's probability of the option the participant actually chose (A, B or None),
# averaged over all of the participant's trials in that session.
# log_lik[t] in the Stan model is log P(chosen option on trial t) under the 3-way softmax
# (logits beta*u[A], beta*u[B], beta*tau), so P(chosen) = exp(log_lik[t]).
# Per draw: mean of exp(log_lik) over the participant's trials -> one posterior per participant x day.
# Summarised by its median (point estimate) and SD (measurement error, used as se).

icc_waves <- c("time1", "time2")

# Trial -> subject_index, in the same row order the model was fitted on (prep_data.R)
df_cbcu_trials <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE)

# The fit files are ~4 GB each: load one, summarise, free it, then the next
df_cp_by_wave <- map(icc_waves, \(wave) {
  df_lookup <- read_csv(file.path(artifacts_dir, paste0("subject_lookup_", wave, ".csv")),
                        show_col_types = FALSE)
  trial_subject <- df_cbcu_trials |>
    filter(time == wave) |>
    arrange(prolific_id, block, trial) |>
    left_join(df_lookup, by = "prolific_id") |>
    pull(subject_index)

  fit      <- readRDS(file.path(artifacts_dir, paste0("fit_", wave, ".rds")))
  prob_chosen <- exp(unclass(fit$draws("log_lik", format = "draws_matrix")))   # draws x trials
  rm(fit)
  gc()
  stopifnot(ncol(prob_chosen) == length(trial_subject))

  # draws x subjects: mean over each subject's trials, per draw
  cp_draws <- sapply(seq_len(nrow(df_lookup)), \(s) rowMeans(prob_chosen[, trial_subject == s, drop = FALSE]))
  rm(prob_chosen)
  gc()

  tibble(subject_index = seq_len(ncol(cp_draws)),
         cp            = apply(cp_draws, 2, median),
         cp_mean       = colMeans(cp_draws),
         se_cp         = apply(cp_draws, 2, sd),
         n_trials      = as.vector(table(trial_subject))) |>
    left_join(df_lookup, by = "subject_index") |>
    transmute(id = prolific_id, day = wave, cp, cp_mean, se_cp, n_trials)
}) |>
  list_rbind()

# Participants with both days
ids_both_days <- df_cp_by_wave |> count(id) |> filter(n == 2) |> pull(id)

df_cp_icc <- df_cp_by_wave |>
  filter(id %in% ids_both_days) |>
  arrange(day, id)

stopifnot(all(between(df_cp_icc$cp, 0, 1)))
write_csv(df_cp_icc, file.path(artifacts_dir, "choice_prediction_icc_data.csv"))

# Size of estimation error relative to the spread of the point estimates, per day
df_cp_icc |>
  group_by(day) |>
  summarise(n_participants = n(),
            mean_cp        = mean(cp),
            mean_se2       = mean(se_cp^2),
            var_estimates  = var(cp),
            noise_ratio    = mean_se2 / var_estimates) |>
  print()
