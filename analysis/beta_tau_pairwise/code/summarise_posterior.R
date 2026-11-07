#### SUMMARISE POSTERIOR (MEDIANS, PER WAVE) ####

# Posterior median (not mean) per subject per parameter.
wave_summaries <- vector("list", length(waves)) |> setNames(waves)

for (wave in waves) {
  fit       <- fit_list[[wave]]
  df_lookup <- subject_lookup[[wave]]

  df_u <- fit$summary("u_matrix", median = median) |>
    mutate(idx     = str_match(variable, "u_matrix\\[(\\d+),(\\d+)\\]"),
           subject_index = as.integer(idx[, 2]),
           item          = as.integer(idx[, 3])) |>
    select(subject_index, item, median) |>
    mutate(item = paste0("u_", item)) |>
    pivot_wider(names_from = item, values_from = median)

  df_beta <- fit$summary("beta", median = median) |>
    mutate(subject_index = as.integer(str_extract(variable, "\\d+"))) |>
    select(subject_index, beta = median)

  df_tau <- fit$summary("tau", median = median) |>
    mutate(subject_index = as.integer(str_extract(variable, "\\d+"))) |>
    select(subject_index, tau = median)

  wave_summaries[[wave]] <- df_lookup |>
    left_join(df_u, by = "subject_index") |>
    left_join(df_beta, by = "subject_index") |>
    left_join(df_tau, by = "subject_index") |>
    mutate(time = wave) |>
    select(prolific_id, time, starts_with("u_"), tau, beta)
}

df_bt_params <- bind_rows(wave_summaries)
