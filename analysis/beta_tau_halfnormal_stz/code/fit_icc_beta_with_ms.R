#### ICC OF BETA ACROSS DAYS, WITH MEASUREMENT ERROR: DATA AND FIT ####
# reads:  artifacts/beta_icc_data_plain.csv (posterior median of beta, from fit_icc_beta_plain.R),
#         artifacts/beta_draws_by_wave.rds (beta draws per wave, from plot_beta_test_retest_posterior.R)
# writes: artifacts/beta_icc_data.csv, artifacts/brms_icc_beta_me.rds
#
# Same model as fit_icc_beta_plain.R, with a measurement layer:
#   measurement: beta_hat_ij ~ Normal(beta_ij, se_ij^2)
#                beta_hat_ij = posterior median of beta, participant i, day j (same values as the plain fit)
#                se_ij       = posterior SD of beta, treated as known
#   model:       beta_ij = b_0 + b_0i + e_ij
# Same point estimate, priors and sampling as the version without measurement error, so the
# two differ only in the measurement layer. ICC is computed in plot_icc_beta.R.

#### 1. DATA: POSTERIOR MEDIAN AND SD OF BETA PER PARTICIPANT X DAY ####

beta_draws_by_wave <- readRDS(file.path(artifacts_dir, "beta_draws_by_wave.rds"))   # draws x participants

df_beta_se <- imap(beta_draws_by_wave, \(draws, wave) {
  tibble(id = colnames(draws), day = wave, se_beta = apply(draws, 2, sd))
}) |>
  list_rbind()

df_beta_icc <- read_csv(file.path(artifacts_dir, "beta_icc_data_plain.csv"), show_col_types = FALSE) |>
  left_join(df_beta_se, by = c("id", "day")) |>
  arrange(day, id)

stopifnot(!anyNA(df_beta_icc$se_beta))
write_csv(df_beta_icc, file.path(artifacts_dir, "beta_icc_data.csv"))

# Size of estimation error relative to the spread of the point estimates, per day
df_beta_icc |>
  group_by(day) |>
  summarise(n_participants = n(),
            mean_beta      = mean(beta),
            mean_se2       = mean(se_beta^2),
            var_estimates  = var(beta),
            noise_ratio    = mean_se2 / var_estimates) |>
  print()

#### 2. PRIORS AND FIT ####

# Raw beta scale. brms bounds sd and sigma at 0, so normal(0, 3) is a half-normal.
priors_beta_icc <- c(
  set_prior("normal(4, 3)", class = "Intercept"),            # b_0, centred on the beta_location prior
  set_prior("normal(0, 3)", class = "sd", group = "id"),     # sigma_b
  set_prior("normal(0, 3)", class = "sigma")                 # sigma_e
)

# se(..., sigma = TRUE): each row's variance is sigma_e^2 + se^2, with se known
fit_beta_icc_me <- brm(
  beta | se(se_beta, sigma = TRUE) ~ 1 + (1 | id),
  data       = df_beta_icc,
  family     = gaussian(),
  prior      = priors_beta_icc,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_beta_me"),
  file_refit = "on_change"
)
