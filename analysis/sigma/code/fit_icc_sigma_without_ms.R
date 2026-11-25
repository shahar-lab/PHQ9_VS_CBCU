#### ICC OF SIGMA ACROSS DAYS, WITHOUT MEASUREMENT ERROR: DATA AND FIT ####
# reads:  artifacts/participant_parameters.csv (sigma = posterior median per participant x day)
# writes: artifacts/sigma_icc_data_plain.csv, artifacts/brms_icc_sigma_plain.rds
#
# Same model as analysis/beta_tau_halfnormal_stz/code/fit_icc_beta_plain.R, with sigma in place
# of beta, on the raw sigma scale (this model's population distribution for sigma is a
# truncated normal):
#   sigma_ij = b_0 + b_0i + e_ij
#   b_0i ~ Normal(0, sigma_b^2)   between-subject
#   e_ij ~ Normal(0, sigma_e^2)   within-subject (includes estimation error)
# No day effect: the day 2 shift in mean sigma goes into sigma_e^2 (absolute agreement).
# The version with a day effect (consistency) is in fit_icc_sigma_day_effect.R.
# ICC is computed in plot_icc_sigma.R.

#### 1. DATA: POSTERIOR MEDIAN OF SIGMA PER PARTICIPANT X DAY ####

df_params <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

# Participants with both days
ids_both_days <- df_params |> count(prolific_id) |> filter(n == 2) |> pull(prolific_id)

df_sigma_icc_plain <- df_params |>
  filter(prolific_id %in% ids_both_days) |>
  select(id = prolific_id, day = time, sigma) |>
  arrange(day, id)

write_csv(df_sigma_icc_plain, file.path(artifacts_dir, "sigma_icc_data_plain.csv"))

#### 2. PRIORS AND FIT ####

# Raw sigma scale. brms bounds sd and sigma at 0, so normal(0, 3) is a half-normal.
# (brms "sigma" here is the residual SD sigma_e, not the choice-model sigma.)
priors_sigma_icc_plain <- c(
  set_prior("normal(5, 3)", class = "Intercept"),            # b_0, centred on the sigma_location prior
  set_prior("normal(0, 3)", class = "sd", group = "id"),     # sigma_b
  set_prior("normal(0, 3)", class = "sigma")                 # sigma_e
)

fit_sigma_icc_plain <- brm(
  sigma ~ 1 + (1 | id),
  data       = df_sigma_icc_plain,
  family     = gaussian(),
  prior      = priors_sigma_icc_plain,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_sigma_plain"),
  file_refit = "on_change"
)
