#### ICC OF SIGMA ACROSS DAYS, WITH MEASUREMENT ERROR: DATA AND FIT ####
# reads:  artifacts/sigma_icc_data_plain.csv (posterior median of sigma, from fit_icc_sigma_without_ms.R),
#         artifacts/sigma_draws_by_wave.rds (sigma draws per wave, from summarise_posterior.R)
# writes: artifacts/sigma_icc_data.csv, artifacts/brms_icc_sigma_me.rds
#
# Same model as fit_icc_sigma_without_ms.R, with a measurement layer
# (as in analysis/beta_tau_halfnormal_stz/code/fit_icc_beta_with_ms.R):
#   measurement: sigma_hat_ij ~ Normal(sigma_ij, se_ij^2)
#                sigma_hat_ij = posterior median of sigma, participant i, day j (same values as the plain fit)
#                se_ij        = posterior SD of sigma, treated as known
#   model:       sigma_ij = b_0 + b_0i + e_ij
# Same point estimate, priors and sampling as the version without measurement error, so the
# two differ only in the measurement layer. ICC is computed in plot_icc_sigma.R.

#### 1. DATA: POSTERIOR MEDIAN AND SD OF SIGMA PER PARTICIPANT X DAY ####

sigma_draws_by_wave <- readRDS(file.path(artifacts_dir, "sigma_draws_by_wave.rds"))   # draws x participants

df_sigma_se <- imap(sigma_draws_by_wave, \(draws, wave) {
  tibble(id = colnames(draws), day = wave, se_sigma = apply(draws, 2, sd))
}) |>
  list_rbind()

df_sigma_icc <- read_csv(file.path(artifacts_dir, "sigma_icc_data_plain.csv"), show_col_types = FALSE) |>
  left_join(df_sigma_se, by = c("id", "day")) |>
  arrange(day, id)

stopifnot(!anyNA(df_sigma_icc$se_sigma))
write_csv(df_sigma_icc, file.path(artifacts_dir, "sigma_icc_data.csv"))

# Size of estimation error relative to the spread of the point estimates, per day
df_sigma_icc |>
  group_by(day) |>
  summarise(n_participants = n(),
            mean_sigma     = mean(sigma),
            mean_se2       = mean(se_sigma^2),
            var_estimates  = var(sigma),
            noise_ratio    = mean_se2 / var_estimates) |>
  print()

#### 2. PRIORS AND FIT ####

# Raw sigma scale. brms bounds sd and sigma at 0, so normal(0, 3) is a half-normal.
priors_sigma_icc <- c(
  set_prior("normal(5, 3)", class = "Intercept"),            # b_0, centred on the sigma_location prior
  set_prior("normal(0, 3)", class = "sd", group = "id"),     # sigma_b
  set_prior("normal(0, 3)", class = "sigma")                 # sigma_e
)

# se(..., sigma = TRUE): each row's variance is sigma_e^2 + se^2, with se known
fit_sigma_icc_me <- brm(
  sigma | se(se_sigma, sigma = TRUE) ~ 1 + (1 | id),
  data       = df_sigma_icc,
  family     = gaussian(),
  prior      = priors_sigma_icc,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_sigma_me"),
  file_refit = "on_change"
)
