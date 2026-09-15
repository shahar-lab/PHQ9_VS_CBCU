#### FIT CROSSED SUBJECT x ITEM MODEL AND EXTRACT SUBJECT-ICC ####

# ASSUMED[no per-fit diagnostic files, per lab precedent set by both sibling
# studies]: with one fit per sample size per outcome (10 fits total across
# both sweeps), convergence is tracked inline instead -- max Rhat and
# divergent-transition count per fit are added as columns to the results
# table.

# Repeated simulate+fit run across sample sizes and two outcomes is the case
# where a custom function is warranted (per coding-rules.md).
fit_and_extract <- function(df, priors) {

  fit <- brm(
    formula = y ~ 1 + (1 | subject) + (1 | item),
    data    = df,
    family  = gaussian(),
    prior   = priors,
    chains  = 4,
    iter    = 2000,
    warmup  = 1000,
    backend = "cmdstanr",
    cores   = 4
  )

  # ASSUMED[exact brms draw column names for a crossed two-random-intercept
  # model]: for `(1 | subject) + (1 | item)` brms names each group-level SD
  # draw column "sd_<group>__Intercept" (group name + "__" + term name) and
  # the residual SD draw column "sigma" -- verified against brms::as_draws_df()
  # naming conventions, extending the two single-random-effect siblings'
  # verified "sd_subject__Intercept"/"sigma" pattern with an additional
  # "sd_item__Intercept" column for the crossed item factor. Subject-ICC is
  # the proportion of total variance attributable to between-subject
  # differences, accounting for the item variance component too.
  sd_subject <- as_draws_df(fit)$sd_subject__Intercept
  sd_item    <- as_draws_df(fit)$sd_item__Intercept
  sigma      <- as_draws_df(fit)$sigma
  icc_draws  <- sd_subject^2 / (sd_subject^2 + sd_item^2 + sigma^2)

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
