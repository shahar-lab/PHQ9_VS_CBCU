#### PLOT CHOICE PREDICTION TEST-RETEST SCATTERS ####
# reads: artifacts/choice_prediction_by_subject.rds
# writes: output/test-retest across sessions/choice_prediction_test_retest_scatter.png (A/B choices only)
#         output/test-retest across sessions/choice_prediction_all_test_retest_scatter.png (A, B and None)
#
# One point per participant: mean predicted probability of the chosen option in
# session 1 vs session 2. Uses plot_test_retest() and widen_by_session() from
# 06_plot_parameter_test_retest.R.

df_choice_prediction <- readRDS(file.path(artifacts_dir, "choice_prediction_by_subject.rds"))

# A/B choices only. Participants with no A/B choices in a session (NA) are
# dropped by widen_by_session()
df_choice_prediction_wide <- df_choice_prediction |>
  select(session, subject, value = choice_prediction) |>
  widen_by_session()

cat(sprintf("Choice prediction (A/B) scatter: %d of %d participants (the rest chose None on every trial of a session)\n",
            nrow(df_choice_prediction_wide), n_subjects))

p_choice_prediction_retest <- plot_test_retest(
  df_choice_prediction_wide,
  "mean choice prediction (A/B choices)",
  "choice_prediction_test_retest_scatter"
)

# All choices, None included: every participant has a value
df_choice_prediction_all_wide <- df_choice_prediction |>
  select(session, subject, value = choice_prediction_all) |>
  widen_by_session()

stopifnot(nrow(df_choice_prediction_all_wide) == n_subjects)

p_choice_prediction_all_retest <- plot_test_retest(
  df_choice_prediction_all_wide,
  "mean choice prediction (A, B and Neither)",
  "choice_prediction_all_test_retest_scatter"
)
