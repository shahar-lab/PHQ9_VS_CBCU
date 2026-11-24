#### EXTRACT SUBJECT ESTIMATES ####
# reads: artifacts/draws_<session>.rds, true_parameters.rds, true_u.rds
# writes: artifacts/participant_parameters.csv / .rds
#
# Posterior median per subject per parameter per session (as in the analysis of
# the real data), with the true values alongside.

true_parameters <- readRDS(file.path(artifacts_dir, "true_parameters.rds"))
true_u          <- readRDS(file.path(artifacts_dir, "true_u.rds"))

sessions <- paste0("session", 1:n_sessions)

df_participant_parameters <- map_dfr(sessions, function(session) {

  draws <- readRDS(file.path(artifacts_dir, paste0("draws_", session, ".rds")))

  df_median <- summarise_draws(subset_draws(draws, c("sigma", "tau", "u_matrix")), median = median)

  df_scalar <- df_median |>
    filter(str_detect(variable, "^(sigma|tau)\\[")) |>
    mutate(parameter = str_extract(variable, "^[a-z]+"),
           subject   = as.integer(str_extract(variable, "\\d+"))) |>
    select(subject, parameter, median) |>
    pivot_wider(names_from = parameter, values_from = median)

  df_u <- df_median |>
    filter(str_starts(variable, "u_matrix")) |>
    mutate(subject = as.integer(str_match(variable, "\\[(\\d+),")[, 2]),
           item    = paste0("u_", str_match(variable, ",(\\d+)\\]")[, 2])) |>
    select(subject, item, median) |>
    pivot_wider(names_from = item, values_from = median)

  df_scalar |>
    left_join(df_u, by = "subject") |>
    mutate(session = session, .before = 1)
})

# True values (identical in both sessions); items only, tau is the None utility
df_true <- true_parameters |>
  select(subject, true_sigma = sigma, true_tau = tau) |>
  bind_cols(as_tibble(true_u[, 1:n_options], .name_repair = ~ paste0("true_u_", seq_along(.x))))

df_participant_parameters <- df_participant_parameters |>
  left_join(df_true, by = "subject") |>
  arrange(session, subject)

stopifnot(nrow(df_participant_parameters) == n_subjects * n_sessions,
          !anyNA(df_participant_parameters))

write_csv(df_participant_parameters, file.path(artifacts_dir, "participant_parameters.csv"))
saveRDS(df_participant_parameters, file.path(artifacts_dir, "participant_parameters.rds"))
