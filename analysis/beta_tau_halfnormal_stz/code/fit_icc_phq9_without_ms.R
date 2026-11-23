#### ICC OF PHQ-9 SUM SCORE ACROSS DAYS: DATA AND FIT ####
# reads:  artifacts/participant_parameters.csv (phq9_sum per participant x day)
# writes: artifacts/phq9_icc_data.csv, artifacts/brms_icc_phq9.rds
#
# Hypothesis 2, eq. [3] as written, on the raw PHQ-9 sum score (0-27):
#   phq9_ij = b_0 + b_0i + e_ij
#   b_0i ~ Normal(0, sigma_b^2)   between-subject
#   e_ij ~ Normal(0, sigma_e^2)   within-subject
# The sum score is observed, so there is no measurement layer (same model as
# fit_icc_tau_without_ms.R). No day effect (absolute agreement).
# ICC (eq. [4]) is computed in plot_icc_phq9.R.

#### 1. DATA: PHQ-9 SUM SCORE PER PARTICIPANT X DAY ####

df_params <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

# Participants with a PHQ-9 sum score on both days
ids_both_days <- df_params |>
  filter(!is.na(phq9_sum)) |>
  count(prolific_id) |>
  filter(n == 2) |>
  pull(prolific_id)

df_phq9_icc <- df_params |>
  filter(prolific_id %in% ids_both_days) |>
  select(id = prolific_id, day = time, phq9_sum) |>
  arrange(day, id)

write_csv(df_phq9_icc, file.path(artifacts_dir, "phq9_icc_data.csv"))

#### 2. PRIORS AND FIT ####

# PHQ-9 sum scale (0-27), set from the scale, not the data: intercept centred on the
# scale midpoint. brms bounds sd and sigma at 0, so normal(0, 7) is a half-normal.
priors_phq9_icc <- c(
  set_prior("normal(13.5, 7)", class = "Intercept"),         # b_0
  set_prior("normal(0, 7)", class = "sd", group = "id"),     # sigma_b
  set_prior("normal(0, 7)", class = "sigma")                 # sigma_e
)

fit_phq9_icc <- brm(
  phq9_sum ~ 1 + (1 | id),
  data       = df_phq9_icc,
  family     = gaussian(),
  prior      = priors_phq9_icc,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_phq9"),
  file_refit = "on_change"
)
