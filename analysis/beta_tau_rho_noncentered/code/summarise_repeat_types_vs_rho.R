#### RHO BY KEY VS NEITHER REPEATING ####
# reads: artifacts/repeat_types.csv · writes: output/repeat types vs rho/*.csv
# Every result is computed twice: all participants, and only those with at least
# min_neither_trials neither choices in the session (stable neither-repeat rates).

df_repeat_types <- read_csv(file.path(artifacts_dir, "repeat_types.csv"), show_col_types = FALSE)

df_samples <- bind_rows(
  mutate(df_repeat_types, sample = "all"),
  mutate(filter(df_repeat_types, enough_neither), sample = "enough_neither")
) |>
  group_by(sample, time) |>
  mutate(key_quartile = ntile(key_excess, 4), neither_quartile = ntile(neither_excess, 4)) |>
  ungroup()

# Quartile tables, key and neither side by side
df_key_quartiles <- df_samples |>
  group_by(sample, time, quartile = key_quartile) |>
  summarise(key_n = n(), key_raw = mean(key_raw), key_chance = mean(key_chance), key_rho = mean(rho), .groups = "drop")

df_neither_quartiles <- df_samples |>
  group_by(sample, time, quartile = neither_quartile) |>
  summarise(neither_n = n(), neither_raw = mean(neither_raw), neither_chance = mean(neither_chance), neither_rho = mean(rho), .groups = "drop")

df_quartiles <- left_join(df_key_quartiles, df_neither_quartiles, by = c("sample", "time", "quartile"))

# Correlations, and both excess rates in one standardized regression
df_regression <- df_samples |>
  group_by(sample, time) |>
  group_modify(~ {
    fit_both <- lm(scale(rho) ~ scale(key_excess) + scale(neither_excess), data = .x)
    coefs    <- tidy(fit_both)
    tibble(
      n               = nrow(.x),
      r_key           = cor(.x$rho, .x$key_excess),
      p_r_key         = cor.test(.x$rho, .x$key_excess)$p.value,
      r_neither       = cor(.x$rho, .x$neither_excess),
      p_r_neither     = cor.test(.x$rho, .x$neither_excess)$p.value,
      beta_key        = coefs$estimate[2],
      p_beta_key      = coefs$p.value[2],
      beta_neither    = coefs$estimate[3],
      p_beta_neither  = coefs$p.value[3],
      r2_both         = glance(fit_both)$r.squared
    )
  }) |>
  ungroup()

# Top key quartile vs top neither quartile; anyone in both top groups is left out of the test
df_top_test <- df_samples |>
  group_by(sample, time) |>
  group_modify(~ {
    in_both     <- .x$key_quartile == 4 & .x$neither_quartile == 4
    rho_key     <- .x$rho[.x$key_quartile == 4 & !in_both]
    rho_neither <- .x$rho[.x$neither_quartile == 4 & !in_both]
    welch       <- t.test(rho_key, rho_neither)
    tibble(
      n_top_key = length(rho_key), n_top_neither = length(rho_neither), n_in_both = sum(in_both),
      mean_rho_top_key = mean(rho_key), mean_rho_top_neither = mean(rho_neither),
      difference = mean(rho_key) - mean(rho_neither),
      ci_low = welch$conf.int[1], ci_high = welch$conf.int[2],
      t = unname(welch$statistic), df = unname(welch$parameter), p_welch = welch$p.value,
      p_wilcoxon = wilcox.test(rho_key, rho_neither)$p.value
    )
  }) |>
  ungroup()

write_csv(df_quartiles, file.path(output_repeat_dir, "repeat_quartiles.csv"))
write_csv(df_regression, file.path(output_repeat_dir, "repeat_regression.csv"))
write_csv(df_top_test, file.path(output_repeat_dir, "repeat_top_quartile_test.csv"))
