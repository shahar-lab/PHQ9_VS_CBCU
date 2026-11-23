#### ICC OF TAU ACROSS DAYS, WITHOUT MEASUREMENT ERROR: DATA AND FIT ####
# reads:  artifacts/participant_parameters.csv (tau = posterior median per participant x day)
# writes: artifacts/tau_icc_data_plain.csv, artifacts/brms_icc_tau_plain.rds
#
# Hypothesis 2, eq. [3] as written, on the observed measure (posterior median of tau):
#   tau_ij = b_0 + b_0i + e_ij
#   b_0i ~ Normal(0, sigma_b^2)   between-subject
#   e_ij ~ Normal(0, sigma_e^2)   within-subject (includes estimation error)
# No day effect (absolute agreement). Same priors and sampling as fit_icc_tau_with_ms.R, so the two
# versions differ only in the measurement layer. ICC (eq. [4]) is computed in plot_icc_tau.R.

#### 1. DATA: POSTERIOR MEDIAN OF TAU PER PARTICIPANT X DAY ####

df_params <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

# Participants with both days
ids_both_days <- df_params |> count(prolific_id) |> filter(n == 2) |> pull(prolific_id)

df_tau_icc_plain <- df_params |>
  filter(prolific_id %in% ids_both_days) |>
  select(id = prolific_id, day = time, tau) |>
  arrange(day, id)

write_csv(df_tau_icc_plain, file.path(artifacts_dir, "tau_icc_data_plain.csv"))

#### 2. PRIORS AND FIT ####

# tau / utility scale. brms bounds sd and sigma at 0, so normal(0, 1) is a half-normal.
priors_tau_icc_plain <- c(
  set_prior("normal(0, 1)", class = "Intercept"),            # b_0
  set_prior("normal(0, 1)", class = "sd", group = "id"),     # sigma_b
  set_prior("normal(0, 1)", class = "sigma")                 # sigma_e
)

fit_tau_icc_plain <- brm(
  tau ~ 1 + (1 | id),
  data       = df_tau_icc_plain,
  family     = gaussian(),
  prior      = priors_tau_icc_plain,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_tau_plain"),
  file_refit = "on_change"
)
