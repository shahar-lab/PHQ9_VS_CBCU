#### DOES NEITHER REPEATING EXPLAIN THE POSITIVE AVERAGE RHO? ####
# reads: artifacts/repeat_types.csv · writes: output/repeat types vs rho/average_rho_check.csv
# The intercept of rho ~ excess is the rho expected for a participant who repeats exactly
# at chance. If neither repeating explains the positive average rho, the intercept should
# drop toward 0 once neither_excess is added next to key_excess.

df_repeat_types <- read_csv(file.path(artifacts_dir, "repeat_types.csv"), show_col_types = FALSE)

df_samples <- bind_rows(
  mutate(df_repeat_types, sample = "all"),
  mutate(filter(df_repeat_types, enough_neither), sample = "enough_neither")
)

df_average_rho_check <- df_samples |>
  group_by(sample, time) |>
  group_modify(~ {
    fit_key  <- lm(rho ~ key_excess, data = .x)
    fit_both <- lm(rho ~ key_excess + neither_excess, data = .x)
    ci_both  <- confint(fit_both)["(Intercept)", ]
    tibble(
      n                   = nrow(.x),
      mean_rho            = mean(.x$rho),
      mean_key_excess     = mean(.x$key_excess),
      p_key_excess        = t.test(.x$key_excess)$p.value,
      mean_neither_excess = mean(.x$neither_excess),
      p_neither_excess    = t.test(.x$neither_excess)$p.value,
      intercept_key_only  = coef(fit_key)[["(Intercept)"]],
      intercept_both      = coef(fit_both)[["(Intercept)"]],
      intercept_both_low  = ci_both[[1]],
      intercept_both_high = ci_both[[2]]
    )
  }) |>
  ungroup()

df_neither_counts <- df_repeat_types |>
  group_by(time) |>
  summarise(n_participants = n(), n_too_few_neither = sum(!enough_neither), .groups = "drop")

write_csv(df_average_rho_check, file.path(output_repeat_dir, "average_rho_check.csv"))
write_csv(df_neither_counts, file.path(output_repeat_dir, "neither_trial_counts.csv"))
