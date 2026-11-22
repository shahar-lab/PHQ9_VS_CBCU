#### SUMMARISE POSTERIOR (MEDIANS, ONE ROW PER SUBJECT) ####
# reads: fit (from fit_model.R; read from artifacts/fit.rds if not in memory),
#        artifacts/subject_lookup.csv

# Posterior median (not mean) per subject per parameter, per user spec.
if (!exists("fit")) fit <- readRDS(file.path(artifacts_dir, "fit.rds"))
subject_lookup <- read_csv(file.path(artifacts_dir, "subject_lookup.csv"), show_col_types = FALSE)

df_u <- fit$summary("u_matrix", median = median) |>
  mutate(idx           = str_match(variable, "u_matrix\\[(\\d+),(\\d+)\\]"),
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

df_bt_params <- subject_lookup |>
  left_join(df_u, by = "subject_index") |>
  left_join(df_beta, by = "subject_index") |>
  left_join(df_tau, by = "subject_index") |>
  select(prolific_id, starts_with("u_"), tau, beta)
