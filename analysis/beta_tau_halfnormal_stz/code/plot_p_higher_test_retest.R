#### P(HIGHER-UTILITY OPTION | NOT NONE): TEST-RETEST SCATTER ####
# reads: artifacts/p_higher_option.csv if it is newer than the fits, otherwise fit_list
#        (from fit_model.R; read from artifacts/fit_<wave>.rds if not in memory) and
#        artifacts/subject_lookup_<wave>.csv
# writes: artifacts/p_higher_option.csv,
#         output/test-retest across sessions/p_higher_test_retest_scatter.png
#
# Measure: given that the subject did not choose None, the probability that they choose
# the option with the higher utility. On a trial with items A and B:
#   P(A | not None) = exp(beta * u_A) / (exp(beta * u_A) + exp(beta * u_B))
#                   = logistic(beta * (u_A - u_B))
# so the probability of the higher-utility option is logistic(beta * |u_A - u_B|).
# tau cancels: it only sets how often None is chosen, not which of A and B wins.
# The measure ranges from 0.5 (A and B chosen at random) to 1 (always the better one).
#
# Every subject saw all 105 item pairs once per session, so the measure is the mean over
# all pairs. It is computed on every posterior draw of beta and u, and the subject's value
# is the posterior median (95% interval also saved).

if (!exists("plot_param_test_retest")) {
  source(file.path(code_dir, "plot_scalar_param_test_retest.R"))   # defines plot_param_test_retest()
}

p_higher_path <- file.path(artifacts_dir, "p_higher_option.csv")
fit_paths     <- file.path(artifacts_dir, paste0("fit_", waves, ".rds"))

# Use the saved values only if they were written after the fits
p_higher_is_fresh <- file.exists(p_higher_path) &&
  all(file.mtime(p_higher_path) > file.mtime(fit_paths[file.exists(fit_paths)]))

if (p_higher_is_fresh) {
  df_p_higher <- read_csv(p_higher_path, show_col_types = FALSE)
} else {
  if (!exists("fit_list")) {
    fit_list <- map(set_names(waves), \(wave) readRDS(file.path(artifacts_dir, paste0("fit_", wave, ".rds"))))
  }

  df_p_higher <- imap(fit_list, \(fit, wave) {
    lookup <- read_csv(file.path(artifacts_dir, paste0("subject_lookup_", wave, ".csv")), show_col_types = FALSE)
    u_draws    <- unclass(fit$draws("u_matrix", format = "draws_matrix"))   # draws x (subject, item)
    beta_draws <- unclass(fit$draws("beta", format = "draws_matrix"))       # draws x subject

    n_items    <- sum(startsWith(colnames(u_draws), "u_matrix[1,"))
    item_pairs <- combn(n_items, 2)

    # One value per posterior draw: mean over all pairs of logistic(beta * |u_A - u_B|)
    # (beta, one value per draw, multiplies each row of the draws x pairs matrix)
    p_higher_one_subject <- function(s) {
      u    <- u_draws[, sprintf("u_matrix[%d,%d]", s, seq_len(n_items))]
      gaps <- abs(u[, item_pairs[1, ]] - u[, item_pairs[2, ]])
      rowMeans(plogis(beta_draws[, sprintf("beta[%d]", s)] * gaps))
    }

    lookup |>
      mutate(draws = map(subject_index, p_higher_one_subject),
             time  = wave,
             p_higher       = map_dbl(draws, median),
             p_higher_lower = map_dbl(draws, \(d) quantile(d, 0.025)),
             p_higher_upper = map_dbl(draws, \(d) quantile(d, 0.975))) |>
      select(prolific_id, time, p_higher, p_higher_lower, p_higher_upper)
  }) |>
    list_rbind()

  write_csv(df_p_higher, p_higher_path)
}

p_p_higher_retest <- plot_param_test_retest(df_p_higher, "p_higher",
                                            "P(higher-utility option | not None)")
