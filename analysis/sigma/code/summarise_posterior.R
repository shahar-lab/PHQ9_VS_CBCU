#### SUMMARISE POSTERIOR (MEDIANS, PER WAVE) ####
# reads: fit_list (from fit_model.R), subject_lookup (from prep_data.R)
# writes: df_bt_params (in memory), artifacts/sigma_draws_by_wave.rds
#
# Posterior median per subject per parameter. tau is the None utility (u[16]);
# u_1..u_15 are the item utilities. Because None is part of the sum-to-zero vector,
# u_1..u_15 sum to -tau, not to 0.
# sigma draws are saved separately (prolific_id x draw) for the HDI plot and for a
# later ICC with measurement error, so the 3+ GB fits need not be reloaded.

wave_summaries <- vector("list", length(waves)) |> setNames(waves)
sigma_draws    <- vector("list", length(waves)) |> setNames(waves)

for (wave in waves) {
  fit       <- fit_list[[wave]]
  df_lookup <- subject_lookup[[wave]]

  df_u <- fit$summary("u_matrix", median = median) |>
    mutate(idx           = str_match(variable, "u_matrix\\[(\\d+),(\\d+)\\]"),
           subject_index = as.integer(idx[, 2]),
           item          = as.integer(idx[, 3])) |>
    select(subject_index, item, median) |>
    mutate(item = paste0("u_", item)) |>
    pivot_wider(names_from = item, values_from = median)

  df_sigma <- fit$summary("sigma", median = median) |>
    mutate(subject_index = as.integer(str_extract(variable, "\\d+"))) |>
    select(subject_index, sigma = median)

  df_tau <- fit$summary("tau", median = median) |>
    mutate(subject_index = as.integer(str_extract(variable, "\\d+"))) |>
    select(subject_index, tau = median)

  wave_summaries[[wave]] <- df_lookup |>
    left_join(df_u, by = "subject_index") |>
    left_join(df_sigma, by = "subject_index") |>
    left_join(df_tau, by = "subject_index") |>
    mutate(time = wave) |>
    select(prolific_id, time, starts_with("u_"), tau, sigma)

  # draws x subjects, columns renamed to prolific_id
  sigma_mat <- unclass(fit$draws("sigma", format = "draws_matrix"))
  colnames(sigma_mat) <- df_lookup$prolific_id[as.integer(str_extract(colnames(sigma_mat), "\\d+"))]
  sigma_draws[[wave]] <- sigma_mat
}

df_bt_params <- bind_rows(wave_summaries)

stopifnot(!anyNA(df_bt_params))

saveRDS(sigma_draws, file.path(artifacts_dir, "sigma_draws_by_wave.rds"))
