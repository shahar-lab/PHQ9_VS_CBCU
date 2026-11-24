#### P(HIGHER-UTILITY OPTION | AN OPTION IS ABOVE TAU): TEST-RETEST SCATTER ####
# reads: artifacts/p_higher_above_tau.csv if it is newer than the fits, otherwise fit_list
#        (from fit_model.R; read from artifacts/fit_<wave>.rds if not in memory) and
#        artifacts/subject_lookup_<wave>.csv
# writes: artifacts/p_higher_above_tau.csv,
#         output/test-retest across sessions/correlation/p_higher_above_tau_test_retest_scatter.png
#
# Measure: on the pairs where at least one of the two items has a utility above tau
# (i.e. at least one option is better than None), the probability of choosing the
# higher-utility item. None is still a possible choice, so (unlike
# plot_p_higher_test_retest.R) tau does not cancel:
#   P(higher) = exp(beta * u_high) / (exp(beta * u_A) + exp(beta * u_B) + exp(beta * tau))
#
# Computed on every posterior draw: the qualifying pairs are those with
# max(u_A, u_B) > tau in that draw, and the draw's value is the mean of P(higher) over them.
# The subject's value is the posterior median (95% interval also saved). A draw with no
# qualifying pair (tau above every utility) has no value and is left out of the median;
# share_draws_with_pair records how many draws had at least one qualifying pair, and
# n_pairs_median the typical number of qualifying pairs (out of 105).

if (!exists("plot_param_test_retest")) {
  source(file.path(code_dir, "plot_scalar_param_test_retest.R"))   # defines plot_param_test_retest()
}

p_higher_above_tau_path <- file.path(artifacts_dir, "p_higher_above_tau.csv")
fit_paths               <- file.path(artifacts_dir, paste0("fit_", waves, ".rds"))

# Use the saved values only if they were written after the fits
p_higher_above_tau_is_fresh <- file.exists(p_higher_above_tau_path) &&
  all(file.mtime(p_higher_above_tau_path) > file.mtime(fit_paths[file.exists(fit_paths)]))

if (p_higher_above_tau_is_fresh) {
  df_p_higher_above_tau <- read_csv(p_higher_above_tau_path, show_col_types = FALSE)
} else {
  if (!exists("fit_list")) {
    fit_list <- map(set_names(waves), \(wave) readRDS(file.path(artifacts_dir, paste0("fit_", wave, ".rds"))))
  }

  df_p_higher_above_tau <- imap(fit_list, \(fit, wave) {
    lookup <- read_csv(file.path(artifacts_dir, paste0("subject_lookup_", wave, ".csv")), show_col_types = FALSE)
    u_draws    <- unclass(fit$draws("u_matrix", format = "draws_matrix"))   # draws x (subject, item)
    beta_draws <- unclass(fit$draws("beta", format = "draws_matrix"))       # draws x subject
    tau_draws  <- unclass(fit$draws("tau", format = "draws_matrix"))        # draws x subject

    n_items    <- sum(startsWith(colnames(u_draws), "u_matrix[1,"))
    item_pairs <- combn(n_items, 2)

    # Per posterior draw: mean P(higher) over the qualifying pairs, and how many qualify.
    # beta and tau (one value per draw) apply to each row of the draws x pairs matrices.
    p_higher_above_tau_one_subject <- function(s) {
      u      <- u_draws[, sprintf("u_matrix[%d,%d]", s, seq_len(n_items))]
      b      <- beta_draws[, sprintf("beta[%d]", s)]
      t      <- tau_draws[, sprintf("tau[%d]", s)]
      u_high <- pmax(u[, item_pairs[1, ]], u[, item_pairs[2, ]])
      u_low  <- pmin(u[, item_pairs[1, ]], u[, item_pairs[2, ]])

      # exp(b * u_high) / (exp(b * u_high) + exp(b * u_low) + exp(b * t)), divided through
      # by exp(b * u_high) so the exponents stay small
      p_high     <- 1 / (1 + exp(b * (u_low - u_high)) + exp(b * (t - u_high)))
      qualifies  <- u_high > t
      p_high[!qualifies] <- NA

      list(p = rowMeans(p_high, na.rm = TRUE),   # NaN for a draw with no qualifying pair
           n_pairs = rowSums(qualifies))
    }

    lookup |>
      mutate(draws = map(subject_index, p_higher_above_tau_one_subject),
             time  = wave,
             p_higher_above_tau       = map_dbl(draws, \(d) median(d$p, na.rm = TRUE)),
             p_higher_above_tau_lower = map_dbl(draws, \(d) quantile(d$p, 0.025, na.rm = TRUE)),
             p_higher_above_tau_upper = map_dbl(draws, \(d) quantile(d$p, 0.975, na.rm = TRUE)),
             share_draws_with_pair    = map_dbl(draws, \(d) mean(d$n_pairs > 0)),
             n_pairs_median           = map_dbl(draws, \(d) median(d$n_pairs))) |>
      select(prolific_id, time, starts_with("p_higher_above_tau"), share_draws_with_pair, n_pairs_median)
  }) |>
    list_rbind()

  write_csv(df_p_higher_above_tau, p_higher_above_tau_path)
}

# Subjects for whom most draws put tau above every utility: their value rests on few draws
print(filter(df_p_higher_above_tau, share_draws_with_pair < 0.5))

p_p_higher_above_tau_retest <- plot_param_test_retest(df_p_higher_above_tau, "p_higher_above_tau",
                                                      "P(higher-utility option | an option above tau)")
