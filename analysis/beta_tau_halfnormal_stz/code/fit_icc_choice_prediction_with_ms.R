#### ICC OF CHOICE PREDICTION ACROSS DAYS, WITH MEASUREMENT ERROR: FIT ####
# reads:  artifacts/choice_prediction_icc_data.csv (from prep_choice_prediction.R)
# writes: artifacts/brms_icc_cp_me.rds
#
# Same model as fit_icc_choice_prediction_without_ms.R, with a measurement layer:
#   measurement: cp_hat_ij ~ Normal(cp_ij, se_ij^2)
#                cp_hat_ij = posterior median of choice prediction, participant i, day j
#                se_ij     = posterior SD of choice prediction, treated as known
#   model:       cp_ij = b_0 + b_0i + e_ij
# Same point estimate, priors and sampling as the version without measurement error, so the
# two differ only in the measurement layer. ICC is computed in plot_icc_choice_prediction.R.

df_cp_icc <- read_csv(file.path(artifacts_dir, "choice_prediction_icc_data.csv"), show_col_types = FALSE)

# Probability scale. brms bounds sd and sigma at 0, so normal(0, 0.25) is a half-normal.
priors_cp_icc <- c(
  set_prior("normal(0.75, 0.25)", class = "Intercept"),       # b_0
  set_prior("normal(0, 0.25)", class = "sd", group = "id"),   # sigma_b
  set_prior("normal(0, 0.25)", class = "sigma")               # sigma_e
)

# se(..., sigma = TRUE): each row's variance is sigma_e^2 + se^2, with se known
fit_cp_icc_me <- brm(
  cp | se(se_cp, sigma = TRUE) ~ 1 + (1 | id),
  data       = df_cp_icc,
  family     = gaussian(),
  prior      = priors_cp_icc,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_cp_me"),
  file_refit = "on_change"
)
