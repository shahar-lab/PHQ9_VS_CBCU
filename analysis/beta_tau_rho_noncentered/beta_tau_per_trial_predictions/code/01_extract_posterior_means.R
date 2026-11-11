#### EXTRACT POSTERIOR MEANS ####

# reads: beta_tau_per_pairwise/artifacts/bt_per_fit_<wave>.rds, subject_lookup_<wave>.csv
# writes: artifacts/posterior_means.rds

# Posterior MEAN per subject (the fits' own participant table reports medians).
means_by_wave <- vector("list", length(waves)) |> setNames(waves)

for (wave in waves) {
  fit       <- readRDS(file.path(fits_dir, paste0("bt_per_fit_", wave, ".rds")))
  df_lookup <- read_csv(file.path(fits_dir, paste0("subject_lookup_", wave, ".csv")), show_col_types = FALSE)

  df_scalars <- c("beta", "tau", "key_decay", "rho") |>
    map(\(par) fit$summary(par, mean) |>
          mutate(subject_index = as.integer(str_extract(variable, "[0-9]+"))) |>
          select(subject_index, !!par := mean)) |>
    reduce(left_join, by = "subject_index")

  df_u <- fit$summary("u_matrix", mean) |>
    mutate(idx = str_match(variable, "u_matrix\\[([0-9]+),([0-9]+)\\]"),
           subject_index = as.integer(idx[, 2]),
           item          = as.integer(idx[, 3])) |>
    select(subject_index, item, u = mean)

  means_by_wave[[wave]] <- list(
    scalars = df_lookup |> left_join(df_scalars, by = "subject_index") |> mutate(time = wave),
    u       = df_u
  )
}

saveRDS(means_by_wave, file.path(artifacts_dir, "posterior_means.rds"))
