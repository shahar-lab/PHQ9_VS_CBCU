#### FIT CBCU + PHQ9 ICC MODELS AND EXTRACT DIFFERENCE ####

# ASSUMED[no per-fit diagnostic files, per user's explicit choice]: with 100 brms
# fits, the lab's usual one-diagnostic.pdf-per-model pattern doesn't scale, so
# convergence is tracked inline instead -- max Rhat and divergent-transition
# count per fit are added as columns to the results table.

# Repeated simulate+fit run 50 times over a loop is the case where a custom
# function is warranted (per coding-rules.md).
fit_and_extract <- function(cbcu_df, phq9_df, priors) {

  cbcu_fit <- brm(
    formula = y ~ 1 + (1 | subject),
    data    = cbcu_df,
    family  = gaussian(),
    prior   = priors,
    chains  = 4,
    iter    = 2000,
    warmup  = 1000,
    backend = "cmdstanr",
    cores   = 4
  )

  phq9_fit <- brm(
    formula = y ~ 1 + (1 | subject),
    data    = phq9_df,
    family  = gaussian(),
    prior   = priors,
    chains  = 4,
    iter    = 2000,
    warmup  = 1000,
    backend = "cmdstanr",
    cores   = 4
  )

  # ASSUMED[exact brms draw column names for a random-intercept-only model]: for
  # `(1 | subject)` brms names the group-level SD draw column "sd_subject__Intercept"
  # (group name + "__" + term name) and the residual SD draw column "sigma" -- verified
  # against brms::as_draws_df() naming conventions for a random-intercept model (this
  # differs from the sibling's random-slope model, which also has sd_subject__y_time2
  # and cor_subject__Intercept__y_time2 columns that do not exist here).
  cbcu_sd_subject <- as_draws_df(cbcu_fit)$sd_subject__Intercept
  cbcu_sigma      <- as_draws_df(cbcu_fit)$sigma
  cbcu_icc_draws  <- cbcu_sd_subject^2 / (cbcu_sd_subject^2 + cbcu_sigma^2)

  phq9_sd_subject <- as_draws_df(phq9_fit)$sd_subject__Intercept
  phq9_sigma      <- as_draws_df(phq9_fit)$sigma
  phq9_icc_draws  <- phq9_sd_subject^2 / (phq9_sd_subject^2 + phq9_sigma^2)

  icc_difference_draws <- cbcu_icc_draws - phq9_icc_draws

  hdi_85 <- ggdist::median_hdi(icc_difference_draws, .width = 0.85)
  hdi_90 <- ggdist::median_hdi(icc_difference_draws, .width = 0.90)
  hdi_95 <- ggdist::median_hdi(icc_difference_draws, .width = 0.95)

  # Convergence tracked inline (max Rhat, divergent transitions) rather than
  # via per-fit diagnostic PDFs -- see ASSUMED note above.
  cbcu_max_rhat    <- max(brms::rhat(cbcu_fit), na.rm = TRUE)
  cbcu_n_divergent <- brms::nuts_params(cbcu_fit) |>
    filter(Parameter == "divergent__") |>
    pull(Value) |>
    sum()

  phq9_max_rhat    <- max(brms::rhat(phq9_fit), na.rm = TRUE)
  phq9_n_divergent <- brms::nuts_params(phq9_fit) |>
    filter(Parameter == "divergent__") |>
    pull(Value) |>
    sum()

  tibble(
    median_diff      = hdi_85$y,
    hdi_width_85     = hdi_85$ymax - hdi_85$ymin,
    hdi_width_90     = hdi_90$ymax - hdi_90$ymin,
    hdi_width_95     = hdi_95$ymax - hdi_95$ymin,
    cbcu_max_rhat    = cbcu_max_rhat,
    cbcu_n_divergent = cbcu_n_divergent,
    phq9_max_rhat    = phq9_max_rhat,
    phq9_n_divergent = phq9_n_divergent
  )
}
