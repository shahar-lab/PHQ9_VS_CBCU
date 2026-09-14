#### FIT PHQ9 ICC MODEL AND EXTRACT POSTERIOR ####

# ASSUMED[no per-fit diagnostic files, per user's explicit choice, matching the
# sibling study]: with one fit per sample size, the lab's usual
# one-diagnostic.pdf-per-model pattern still doesn't scale well across a
# sweep, so convergence is tracked inline instead -- max Rhat and
# divergent-transition count per fit are added as columns to the results
# table.

# Repeated simulate+fit run across sample sizes is the case where a custom
# function is warranted (per coding-rules.md).
fit_and_extract <- function(df, priors) {

  fit <- brm(
    formula = y ~ 1 + (1 | subject),
    data    = df,
    family  = gaussian(),
    prior   = priors,
    chains  = 4,
    iter    = 2000,
    warmup  = 1000,
    backend = "cmdstanr",
    cores   = 4
  )

  # ASSUMED[exact brms draw column names for a random-intercept-only model]:
  # for `(1 | subject)` brms names the group-level SD draw column
  # "sd_subject__Intercept" (group name + "__" + term name) and the residual
  # SD draw column "sigma" -- verified against brms::as_draws_df() naming
  # conventions for a random-intercept model, matching the ICC sibling's
  # single-task fits (same random-intercept-only structure).
  sd_subject <- as_draws_df(fit)$sd_subject__Intercept
  sigma      <- as_draws_df(fit)$sigma
  icc_draws  <- sd_subject^2 / (sd_subject^2 + sigma^2)

  hdi_85 <- ggdist::median_hdi(icc_draws, .width = 0.85)
  hdi_90 <- ggdist::median_hdi(icc_draws, .width = 0.90)
  hdi_95 <- ggdist::median_hdi(icc_draws, .width = 0.95)

  # Convergence tracked inline (max Rhat, divergent transitions) rather than
  # via per-fit diagnostic PDFs -- see ASSUMED note above.
  max_rhat    <- max(brms::rhat(fit), na.rm = TRUE)
  n_divergent <- brms::nuts_params(fit) |>
    filter(Parameter == "divergent__") |>
    pull(Value) |>
    sum()

  tibble(
    median_icc   = hdi_85$y,
    hdi_width_85 = hdi_85$ymax - hdi_85$ymin,
    hdi_width_90 = hdi_90$ymax - hdi_90$ymin,
    hdi_width_95 = hdi_95$ymax - hdi_95$ymin,
    max_rhat     = max_rhat,
    n_divergent  = n_divergent
  )
}
