#### ICC OF TAU ACROSS DAYS: DATA AND FIT ####
# reads:  artifacts/fit_time1.rds, artifacts/fit_time2.rds,
#         artifacts/subject_lookup_time1.csv, artifacts/subject_lookup_time2.csv
# writes: artifacts/tau_icc_data.csv, artifacts/brms_icc_tau_me.rds
#
# Hypothesis 2, eq. [3], with a measurement layer:
#   measurement: tau_hat_ij ~ Normal(tau_ij, se_ij^2)
#                tau_hat_ij = posterior mean of tau, participant i, day j
#                se_ij      = posterior SD of tau, treated as known
#   model [3]:   tau_ij = b_0 + b_0i + e_ij
#                b_0i ~ Normal(0, sigma_b^2)   between-subject
#                e_ij ~ Normal(0, sigma_e^2)   within-subject, net of estimation error
# No day effect: a shift shared by everyone on day 2 goes into sigma_e^2 (absolute agreement).
# The ICC (eq. [4]) is computed per posterior draw in plot_icc_tau.R.

#### 1. DATA: POSTERIOR MEAN AND SD OF TAU PER PARTICIPANT X DAY ####

icc_waves <- c("time1", "time2")

# The fit files are ~4 GB each: load one, summarise tau, free it, then the next
df_tau_by_wave <- map(icc_waves, \(wave) {
  fit       <- readRDS(file.path(artifacts_dir, paste0("fit_", wave, ".rds")))
  df_lookup <- read_csv(file.path(artifacts_dir, paste0("subject_lookup_", wave, ".csv")),
                        show_col_types = FALSE)
  df_wave <- fit$summary("tau", mean = mean, sd = sd) |>
    mutate(subject_index = as.integer(str_extract(variable, "\\d+"))) |>
    left_join(df_lookup, by = "subject_index") |>
    transmute(id = prolific_id, day = wave, tau = mean, se_tau = sd)
  rm(fit)
  gc()
  df_wave
}) |>
  list_rbind()

# Participants with both days
ids_both_days <- df_tau_by_wave |> count(id) |> filter(n == 2) |> pull(id)

df_tau_icc <- df_tau_by_wave |>
  filter(id %in% ids_both_days) |>
  arrange(day, id)

write_csv(df_tau_icc, file.path(artifacts_dir, "tau_icc_data.csv"))

# Size of estimation error relative to the spread of the point estimates, per day
df_tau_icc |>
  group_by(day) |>
  summarise(n_participants = n(),
            mean_se2       = mean(se_tau^2),
            var_estimates  = var(tau),
            noise_ratio    = mean_se2 / var_estimates) |>
  print()

#### 2. PRIORS AND FIT ####

# tau / utility scale. brms bounds sd and sigma at 0, so normal(0, 1) is a half-normal.
priors_tau_icc <- c(
  set_prior("normal(0, 1)", class = "Intercept"),            # b_0
  set_prior("normal(0, 1)", class = "sd", group = "id"),     # sigma_b
  set_prior("normal(0, 1)", class = "sigma")                 # sigma_e
)

# se(..., sigma = TRUE): each row's variance is sigma_e^2 + se^2, with se known
fit_tau_icc <- brm(
  tau | se(se_tau, sigma = TRUE) ~ 1 + (1 | id),
  data       = df_tau_icc,
  family     = gaussian(),
  prior      = priors_tau_icc,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_tau_me"),
  file_refit = "on_change"
)
