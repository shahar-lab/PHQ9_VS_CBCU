#### FIT LIKERT + CBCU RELIABILITY MODELS AND EXTRACT DIFFERENCE ####

# ASSUMED[no per-fit diagnostic files, per user's explicit choice]: with 100 brms
# fits, the lab's usual one-diagnostic.pdf-per-model pattern doesn't scale, so
# convergence is tracked inline instead -- max Rhat and divergent-transition
# count per fit are added as columns to the results table.

# Repeated simulate+fit run 50 times over a loop is the case where a custom
# function is warranted (per coding-rules.md).
fit_and_extract <- function(likert_df, cbcu_df, priors) {

  likert_fit_df <- likert_df |>
    rename(y_time1 = likert_time1, y_time2 = likert_time2)

  cbcu_fit_df <- cbcu_df |>
    rename(y_time1 = cbcu_time1, y_time2 = cbcu_time2)

  likert_fit <- brm(
    formula = y_time1 ~ y_time2 + (y_time2 | subject),
    data    = likert_fit_df,
    family  = gaussian(),
    prior   = priors,
    chains  = 4,
    iter    = 2000,
    warmup  = 1000,
    backend = "cmdstanr",
    cores   = 4
  )

  cbcu_fit <- brm(
    formula = y_time1 ~ y_time2 + (y_time2 | subject),
    data    = cbcu_fit_df,
    family  = gaussian(),
    prior   = priors,
    chains  = 4,
    iter    = 2000,
    warmup  = 1000,
    backend = "cmdstanr",
    cores   = 4
  )

  # Fixed-effect slope on standardized data equals the population correlation
  # estimate directly -- this is the target quantity, not any random-effects
  # intercept-slope correlation and not a rescaled slope.
  likert_draws <- as_draws_df(likert_fit)$b_y_time2
  cbcu_draws   <- as_draws_df(cbcu_fit)$b_y_time2

  difference_draws <- cbcu_draws - likert_draws

  hdi_85 <- ggdist::median_hdi(difference_draws, .width = 0.85)
  hdi_90 <- ggdist::median_hdi(difference_draws, .width = 0.90)
  hdi_95 <- ggdist::median_hdi(difference_draws, .width = 0.95)

  # Convergence tracked inline (max Rhat, divergent transitions) rather than
  # via per-fit diagnostic PDFs -- see ASSUMED note above.
  likert_max_rhat    <- max(brms::rhat(likert_fit), na.rm = TRUE)
  likert_n_divergent <- brms::nuts_params(likert_fit) |>
    filter(Parameter == "divergent__") |>
    pull(Value) |>
    sum()

  cbcu_max_rhat    <- max(brms::rhat(cbcu_fit), na.rm = TRUE)
  cbcu_n_divergent <- brms::nuts_params(cbcu_fit) |>
    filter(Parameter == "divergent__") |>
    pull(Value) |>
    sum()

  tibble(
    median_diff        = hdi_85$y,
    hdi_width_85       = hdi_85$ymax - hdi_85$ymin,
    hdi_width_90       = hdi_90$ymax - hdi_90$ymin,
    hdi_width_95       = hdi_95$ymax - hdi_95$ymin,
    likert_max_rhat    = likert_max_rhat,
    likert_n_divergent = likert_n_divergent,
    cbcu_max_rhat      = cbcu_max_rhat,
    cbcu_n_divergent   = cbcu_n_divergent
  )
}
