#### BUILD TRIAL TABLE ####

# reads: data/processed/cbcu.csv, artifacts/posterior_means.rds
# writes: artifacts/processed_data_and_parameters.csv

means_by_wave <- readRDS(file.path(artifacts_dir, "posterior_means.rds"))

df_cbcu <- read_csv(file.path(data_path, "cbcu.csv"), show_col_types = FALSE)

# Same trial order as the fits (analysis/beta_tau_per_pairwise/code/prep_data.R)
df <- df_cbcu |>
  filter(time %in% waves) |>
  arrange(time, prolific_id, block, trial) |>
  mutate(choice_int = case_when(choice == "left"  ~ 1L,
                                choice == "right" ~ 2L,
                                choice == "skip"  ~ 3L))

df_scalars <- map(means_by_wave, "scalars") |> bind_rows()
df_u       <- map2(means_by_wave, names(means_by_wave), \(x, w) mutate(x$u, time = w)) |>
  bind_rows()

df <- df |>
  left_join(df_scalars, by = c("prolific_id", "time")) |>
  left_join(df_u |> rename(item_number_left  = item, utility_A = u),
            by = c("subject_index", "time", "item_number_left")) |>
  left_join(df_u |> rename(item_number_right = item, utility_B = u),
            by = c("subject_index", "time", "item_number_right")) |>
  rename(decay = key_decay)

# key_contrib: running perseveration value before each trial, reset on a subject's first trial
df <- df |>
  group_by(time, prolific_id) |>
  group_modify(\(d, key) {
    key_value <- c(0, 0, 0)
    contrib   <- matrix(0, nrow(d), 3)
    for (t in seq_len(nrow(d))) {
      contrib[t, ] <- key_value
      key_value    <- key_value * d$decay[t]
      key_value[d$choice_int[t]] <- key_value[d$choice_int[t]] + d$rho[t]
    }
    d |> mutate(key_contrib_A = contrib[, 1], key_contrib_B = contrib[, 2], key_contrib_None = contrib[, 3])
  }) |>
  ungroup()

# Softmax of the log-weights = exp(categorical_logit)
df <- df |>
  mutate(log_weight_A    = beta * utility_A + key_contrib_A,
         log_weight_B    = beta * utility_B + key_contrib_B,
         log_weight_None = tau + key_contrib_None,
         denominator     = exp(log_weight_A) + exp(log_weight_B) + exp(log_weight_None),
         prob_A          = exp(log_weight_A) / denominator,
         prob_B          = exp(log_weight_B) / denominator,
         prob_None       = exp(log_weight_None) / denominator,
         choice_AB       = case_when(choice == "left"  ~ "A",
                                     choice == "right" ~ "B",
                                     choice == "skip"  ~ "None")) |>
  select(-c(log_weight_A, log_weight_B, log_weight_None, denominator, choice_int, subject_index))

stopifnot(all(abs(df$prob_A + df$prob_B + df$prob_None - 1) < 1e-9),
          nrow(df) == nrow(filter(df_cbcu, time %in% waves)),
          !anyNA(df$prob_A))

write_csv(df, file.path(artifacts_dir, "processed_data_and_parameters.csv"))
