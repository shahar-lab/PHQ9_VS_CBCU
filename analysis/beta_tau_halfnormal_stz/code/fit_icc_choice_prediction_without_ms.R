#### ICC OF CHOICE PREDICTION ACROSS DAYS, WITHOUT MEASUREMENT ERROR: FIT ####
# reads:  artifacts/choice_prediction_icc_data.csv (from prep_choice_prediction.R)
# writes: artifacts/brms_icc_cp_plain.rds
#
# Random-intercept model on the observed measure (posterior median of choice prediction):
#   cp_ij = b_0 + b_0i + e_ij
#   b_0i ~ Normal(0, sigma_b^2)   between-subject
#   e_ij ~ Normal(0, sigma_e^2)   within-subject (includes estimation error)
# Raw probability scale. No day effect (absolute agreement).
# ICC = sigma_b^2 / (sigma_b^2 + sigma_e^2) is computed in plot_icc_choice_prediction.R.

df_cp_icc <- read_csv(file.path(artifacts_dir, "choice_prediction_icc_data.csv"), show_col_types = FALSE)

# Probability scale. brms bounds sd and sigma at 0, so normal(0, 0.25) is a half-normal.
priors_cp_icc <- c(
  set_prior("normal(0.75, 0.25)", class = "Intercept"),       # b_0
  set_prior("normal(0, 0.25)", class = "sd", group = "id"),   # sigma_b
  set_prior("normal(0, 0.25)", class = "sigma")               # sigma_e
)

fit_cp_icc_plain <- brm(
  cp ~ 1 + (1 | id),
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
  file       = file.path(artifacts_dir, "brms_icc_cp_plain"),
  file_refit = "on_change"
)
