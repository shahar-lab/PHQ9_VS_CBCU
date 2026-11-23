#### ICC OF BETA ACROSS DAYS, WITHOUT MEASUREMENT ERROR: DATA AND FIT ####
# reads:  artifacts/participant_parameters.csv (beta = posterior median per participant x day)
# writes: artifacts/beta_icc_data_plain.csv, artifacts/brms_icc_beta_plain.rds
#
# Hypothesis 2, eq. [3] as written, on the observed measure (posterior median of beta),
# on the raw beta scale (this model's population distribution for beta is a truncated normal):
#   beta_ij = b_0 + b_0i + e_ij
#   b_0i ~ Normal(0, sigma_b^2)   between-subject
#   e_ij ~ Normal(0, sigma_e^2)   within-subject (includes estimation error)
# No day effect: the day 2 shift in mean beta goes into sigma_e^2 (absolute agreement).
# ICC (eq. [4]) is computed in plot_icc_beta.R.

#### 1. DATA: POSTERIOR MEDIAN OF BETA PER PARTICIPANT X DAY ####

df_params <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

# Participants with both days
ids_both_days <- df_params |> count(prolific_id) |> filter(n == 2) |> pull(prolific_id)

df_beta_icc_plain <- df_params |>
  filter(prolific_id %in% ids_both_days) |>
  select(id = prolific_id, day = time, beta) |>
  arrange(day, id)

write_csv(df_beta_icc_plain, file.path(artifacts_dir, "beta_icc_data_plain.csv"))

#### 2. PRIORS AND FIT ####

# Raw beta scale. brms bounds sd and sigma at 0, so normal(0, 3) is a half-normal.
priors_beta_icc_plain <- c(
  set_prior("normal(4, 3)", class = "Intercept"),            # b_0, centred on the beta_location prior
  set_prior("normal(0, 3)", class = "sd", group = "id"),     # sigma_b
  set_prior("normal(0, 3)", class = "sigma")                 # sigma_e
)

fit_beta_icc_plain <- brm(
  beta ~ 1 + (1 | id),
  data       = df_beta_icc_plain,
  family     = gaussian(),
  prior      = priors_beta_icc_plain,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_beta_plain"),
  file_refit = "on_change"
)
