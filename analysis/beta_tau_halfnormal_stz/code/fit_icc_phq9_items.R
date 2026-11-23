#### ICC OF PHQ-9 ITEM RATINGS ACROSS OCCASIONS: DATA AND FIT ####
# reads:  artifacts/participant_parameters.csv (phq9_1..phq9_9, ratings 0-3, per participant x occasion)
# writes: artifacts/phq9_items_icc_data.csv, artifacts/brms_icc_phq9_items.rds
#
# Same reliability model as the CBCU utilities (fit_icc_utility_without_ms.R):
#   rating_pok = b_0 + a_k + c_pk + d_ok + e_pok
#   a_k  ~ Normal(0, sigma_item^2)               item
#   c_pk ~ Normal(0, sigma_participant:item^2)   participant x item (stable symptom profile)
#   d_ok ~ Normal(0, sigma_occasion:item^2)      occasion x item (an item shifts for everyone)
#   e_pok ~ Normal(0, sigma^2)                   residual (participant x occasion x item)
# Ratings are centred (not scaled) within participant x occasion, so a participant intercept
# and a participant x occasion term would have variance exactly zero: neither is in the model.
# Flat profiles (all 9 ratings equal) are kept; after centring they are all zeros.
# ICC is computed per posterior draw in plot_icc_items.R.

#### 1. DATA: ONE ROW PER PARTICIPANT X OCCASION X ITEM ####

df_params <- read_csv(file.path(artifacts_dir, "participant_parameters.csv"), show_col_types = FALSE)

# Participants with both occasions (the same 185 as the CBCU utilities)
ids_both_occasions <- df_params |> count(prolific_id) |> filter(n == 2) |> pull(prolific_id)

df_phq9_items_icc <- df_params |>
  filter(prolific_id %in% ids_both_occasions) |>
  select(participant = prolific_id, occasion = time, phq9_1:phq9_9) |>
  pivot_longer(phq9_1:phq9_9, names_to = "item", names_prefix = "phq9_", values_to = "rating_raw") |>
  mutate(item = factor(as.integer(item))) |>
  # Centre to mean 0 within participant x occasion (no scaling)
  group_by(participant, occasion) |>
  mutate(rating = rating_raw - mean(rating_raw)) |>
  ungroup() |>
  arrange(occasion, participant, item)

# Check: mean 0 in every participant x occasion; count flat profiles
df_phq9_items_icc |>
  group_by(participant, occasion) |>
  summarise(m = mean(rating), flat = all(rating == 0), .groups = "drop") |>
  summarise(n_cells = n(), max_abs_mean = max(abs(m)), n_flat_profiles = sum(flat)) |>
  print()

write_csv(df_phq9_items_icc, file.path(artifacts_dir, "phq9_items_icc_data.csv"))

#### 2. PRIORS AND FIT ####

# Centred rating scale (within-person SD about 0.7). brms bounds sd and sigma at 0,
# so normal(0, 1) is a half-normal.
priors_phq9_items_icc <- c(
  set_prior("normal(0, 1)", class = "Intercept"),                           # b_0
  set_prior("normal(0, 1)", class = "sd", group = "item"),                  # sigma_item
  set_prior("normal(0, 1)", class = "sd", group = "participant:item"),      # sigma_participant:item
  set_prior("normal(0, 1)", class = "sd", group = "occasion:item"),         # sigma_occasion:item
  set_prior("normal(0, 1)", class = "sigma")                                # sigma (residual)
)

fit_phq9_items_icc <- brm(
  rating ~ 1 + (1 | item) + (1 | participant:item) + (1 | occasion:item),
  data       = df_phq9_items_icc,
  family     = gaussian(),
  prior      = priors_phq9_items_icc,
  chains     = 4,
  cores      = 4,
  iter       = 3000,
  warmup     = 1000,
  control    = list(adapt_delta = 0.95),
  seed       = 2026,
  backend    = "cmdstanr",
  file       = file.path(artifacts_dir, "brms_icc_phq9_items"),
  file_refit = "on_change"
)
