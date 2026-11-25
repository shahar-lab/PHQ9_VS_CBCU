#### ICC OF SIGMA ACROSS DAYS, WITH A DAY EFFECT (CONSISTENCY): FITS ####
# reads:  artifacts/sigma_icc_data.csv (posterior median and SD of sigma, from fit_icc_sigma_with_ms.R)
# writes: artifacts/brms_icc_sigma_day_plain.rds, artifacts/brms_icc_sigma_day_me.rds
#
# Same two models as fit_icc_sigma_without_ms.R and fit_icc_sigma_with_ms.R, plus a fixed
# day effect delta (mean change in sigma from day 1 to day 2):
#   sigma_ij = b_0 + delta * [j = day 2] + b_0i + e_ij
# The shared shift between days is removed from sigma_e^2, so
# ICC = sigma_b^2 / (sigma_b^2 + sigma_e^2) is a consistency ICC (ICC(C,1)), not absolute
# agreement. Without the day effect the shift sits in sigma_e^2 (agreement).
# Same data, priors and sampling as the versions without the day effect, plus a prior on delta.

df_sigma_icc_day <- read_csv(file.path(artifacts_dir, "sigma_icc_data.csv"), show_col_types = FALSE) |>
  arrange(day, id)

# brms centres the intercept on the mean of the predictors, so the Intercept prior keeps its meaning
priors_sigma_icc_day <- c(
  set_prior("normal(5, 3)", class = "Intercept"),            # b_0, centred on the sigma_location prior
  set_prior("normal(0, 3)", class = "b"),                    # delta, day 2 - day 1
  set_prior("normal(0, 3)", class = "sd", group = "id"),     # sigma_b
  set_prior("normal(0, 3)", class = "sigma")                 # sigma_e
)

# Without measurement error: posterior medians
fit_sigma_icc_day_plain <- brm(
  sigma ~ 1 + day + (1 | id),
  data       = df_sigma_icc_day,
  family     = gaussian(),
  prior      = priors_sigma_icc_day,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_sigma_day_plain"),
  file_refit = "on_change"
)

# With measurement error: same medians, posterior SD as known se
fit_sigma_icc_day_me <- brm(
  sigma | se(se_sigma, sigma = TRUE) ~ 1 + day + (1 | id),
  data       = df_sigma_icc_day,
  family     = gaussian(),
  prior      = priors_sigma_icc_day,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_sigma_day_me"),
  file_refit = "on_change"
)
